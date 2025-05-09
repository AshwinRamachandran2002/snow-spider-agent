WITH
/* 1.  Sorafenib drug IDs (from names and synonyms) */
sorafenib_drugs AS (
  SELECT DISTINCT drugID
  FROM `isb-cgc-bq.targetome_versioned.drug_synonyms_v1`
  WHERE LOWER(synonym) = 'sorafenib'
  UNION DISTINCT
  SELECT DISTINCT drugID
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1`
  WHERE LOWER(drugName) = 'sorafenib'
),

/* 2.  Sorafenib → target interactions that satisfy the assay‑value filters              */
filtered_targets AS (
  SELECT DISTINCT i.targetID,
                  i.target_uniprotID
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1`   i
  JOIN sorafenib_drugs                                    sd ON sd.drugID = i.drugID
  JOIN `isb-cgc-bq.targetome_versioned.experiments_v1`    e  ON e.expID   = i.expID
  WHERE i.targetSpecies        = 'Homo sapiens'
    AND e.exp_assayValueMedian IS NOT NULL
    AND e.exp_assayValueMedian <= 100
    AND (e.exp_assayValueLow  IS NULL OR e.exp_assayValueLow  <= 100)
    AND (e.exp_assayValueHigh IS NULL OR e.exp_assayValueHigh <= 100)
),

/* 3.  Map those targets to Reactome physical entities via UniProt ID                    */
sorafenib_pe AS (
  SELECT DISTINCT pe.stable_id
  FROM filtered_targets ft
  JOIN `isb-cgc-bq.reactome_versioned.physical_entity_v77` pe
    ON pe.uniprot_id = ft.target_uniprotID
),

/* 4.  Universe: all H. sapiens physical entities that have TAS evidence to  
        lowest‑level Reactome pathways                                                    */
all_pe AS (
  SELECT DISTINCT pp.pe_stable_id AS stable_id
  FROM `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` pp
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77`       pw
    ON pw.stable_id = pp.pathway_stable_id
  WHERE pp.evidence_code = 'TAS'
    AND pw.species       = 'Homo sapiens'
    AND pw.lowest_level  = TRUE
),

total_counts AS (
  SELECT
    (SELECT COUNT(*) FROM sorafenib_pe) AS total_targets,
    (SELECT COUNT(*) FROM all_pe     ) AS total_pe
),

/* 5.  For every lowest‑level pathway, count sorafenib targets & total entities           */
pathway_stats AS (
  SELECT
    pw.stable_id                                          AS pathway_id,
    pw.name                                               AS pathway_name,
    COUNT(DISTINCT IF(sp.stable_id IS NOT NULL,
                      pp.pe_stable_id, NULL))            AS targets_in_pathway,
    COUNT(DISTINCT pp.pe_stable_id)                      AS total_pe_in_pathway
  FROM `isb-cgc-bq.reactome_versioned.pathway_v77`        pw
  JOIN `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77`  pp
    ON pw.stable_id = pp.pathway_stable_id
  LEFT JOIN sorafenib_pe                                  sp
    ON sp.stable_id = pp.pe_stable_id
  WHERE pp.evidence_code = 'TAS'
    AND pw.species      = 'Homo sapiens'
    AND pw.lowest_level = TRUE
  GROUP BY pathway_id, pathway_name
),

/* 6.  2×2 table values and chi‑squared statistic                                          */
chi2 AS (
  SELECT
    ps.pathway_id,
    ps.pathway_name,
    ps.targets_in_pathway                                AS targets_in_pathway,
    (tc.total_targets - ps.targets_in_pathway)           AS targets_outside_pathway,
    (ps.total_pe_in_pathway - ps.targets_in_pathway)     AS nontargets_in_pathway,
    (tc.total_pe - tc.total_targets)
      - (ps.total_pe_in_pathway - ps.targets_in_pathway) AS nontargets_outside_pathway,
    SAFE_DIVIDE(
      POW(
        (ps.targets_in_pathway *
         ((tc.total_pe - tc.total_targets)
           - (ps.total_pe_in_pathway - ps.targets_in_pathway))
         - (tc.total_targets - ps.targets_in_pathway) *
           (ps.total_pe_in_pathway - ps.targets_in_pathway)
        ), 2) * tc.total_pe,
      (tc.total_targets *
       (tc.total_pe - tc.total_targets) *
       ps.total_pe_in_pathway *
       (tc.total_pe - ps.total_pe_in_pathway))
    )                                                   AS chi_squared
  FROM pathway_stats ps
  CROSS JOIN total_counts tc
)

/* 7.  Return the three pathways with the highest chi‑squared values                      */
SELECT
  pathway_id,
  pathway_name,
  targets_in_pathway,
  targets_outside_pathway,
  nontargets_in_pathway,
  nontargets_outside_pathway,
  chi_squared
FROM chi2
WHERE chi_squared IS NOT NULL
ORDER BY chi_squared DESC
LIMIT 3;