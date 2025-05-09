WITH
/* sorafenib drugID(s)                                                      */
soraf_drug AS (
  SELECT DISTINCT drugID
  FROM   `isb-cgc-bq.targetome_versioned.drug_synonyms_v1`
  WHERE  LOWER(synonym) LIKE '%sorafenib%'
),

/* potent Homo‑sapiens sorafenib targets (median ≤100 nM, low/high ≤100 nM) */
soraf_targets AS (
  SELECT DISTINCT p.stable_id AS pe_id
  FROM   `isb-cgc-bq.targetome_versioned.interactions_v1`   i
  JOIN   `isb-cgc-bq.targetome_versioned.experiments_v1`    e
         ON  i.expID = e.expID
  JOIN   soraf_drug  d
         ON  i.drugID = d.drugID
  JOIN   `isb-cgc-bq.reactome_versioned.physical_entity_v77` p
         ON  i.target_uniprotID = p.uniprot_id
  WHERE  i.targetSpecies          = 'Homo sapiens'
    AND  e.exp_assayValueMedian  <= 100
    AND (e.exp_assayValueLow     <= 100 OR e.exp_assayValueLow  IS NULL)
    AND (e.exp_assayValueHigh    <= 100 OR e.exp_assayValueHigh IS NULL)
),

/* background universe: every PE having TAS evidence to any pathway        */
tas_pe_universe AS (
  SELECT DISTINCT pe_stable_id AS pe_id
  FROM   `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77`
  WHERE  evidence_code = 'TAS'
),

/* PE → pathway edges that are  (i) TAS–supported, (ii) human, (iii) lowest‑level */
pathway_pe AS (
  SELECT DISTINCT ptw.pathway_stable_id AS pathway_id,
                  ptw.pe_stable_id      AS pe_id
  FROM   `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` ptw
  JOIN   `isb-cgc-bq.reactome_versioned.pathway_v77`       pw
         ON  pw.stable_id = ptw.pathway_stable_id
  WHERE  ptw.evidence_code = 'TAS'
    AND  pw.lowest_level   = TRUE
    AND  pw.species        = 'Homo sapiens'
),

/* 2×2 contingency counts for every pathway                                */
contingency AS (
  SELECT
    pw.stable_id                                           AS pathway_id,
    pw.name                                                AS pathway_name,
    COUNTIF(pp.pe_id IN (SELECT pe_id FROM soraf_targets))     AS a_targets_in,
    COUNTIF(pp.pe_id NOT IN (SELECT pe_id FROM soraf_targets)) AS c_nontargets_in,
    (SELECT COUNT(*) FROM soraf_targets)
      - COUNTIF(pp.pe_id IN (SELECT pe_id FROM soraf_targets)) AS b_targets_out,
    (SELECT COUNT(*) FROM tas_pe_universe)
      - (SELECT COUNT(*) FROM soraf_targets)
      - COUNTIF(pp.pe_id NOT IN (SELECT pe_id FROM soraf_targets)) AS d_nontargets_out
  FROM   pathway_pe                       pp
  JOIN   `isb-cgc-bq.reactome_versioned.pathway_v77` pw
         ON pw.stable_id = pp.pathway_id
  GROUP  BY pathway_id, pathway_name
),

/* χ² statistic for each pathway                                            */
chi2 AS (
  SELECT
    *,
    ( (a_targets_in + b_targets_out + c_nontargets_in + d_nontargets_out)
      * POW( (a_targets_in * d_nontargets_out) -
             (b_targets_out * c_nontargets_in), 2 )
      / ( (a_targets_in + b_targets_out)
          * (c_nontargets_in + d_nontargets_out)
          * (a_targets_in + c_nontargets_in)
          * (b_targets_out + d_nontargets_out) )
    ) AS chi_squared
  FROM contingency
)

/* top‑3 lowest‑level pathways with the highest χ² values                   */
SELECT
  pathway_id,
  pathway_name,
  a_targets_in      AS targets_in_pathway,
  b_targets_out     AS targets_outside_pathway,
  c_nontargets_in   AS nontargets_in_pathway,
  d_nontargets_out  AS nontargets_outside_pathway,
  chi_squared
FROM   chi2
ORDER  BY chi_squared DESC
LIMIT  3;