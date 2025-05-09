-- Top three lowest-level Homo sapiens Reactome pathways (TAS evidence)
-- with the highest χ² enrichment for potent sorafenib targets
WITH
/* 1.  Potent Homo sapiens sorafenib targets (UniProt IDs)              */
sorafenib_targets AS (
  SELECT DISTINCT i.target_uniprotID
  FROM  `isb-cgc-bq.targetome_versioned.interactions_v1` AS i
  JOIN  `isb-cgc-bq.targetome_versioned.experiments_v1`  AS e
         ON i.expID = e.expID
  WHERE i.drugID = 157                             -- sorafenib
    AND LOWER(i.targetSpecies)  = 'homo sapiens'
    AND e.exp_assayUnits        = 'nM'
    AND e.exp_assayValueMedian <= 100
    AND (e.exp_assayValueLow  <= 100 OR e.exp_assayValueLow  IS NULL)
    AND (e.exp_assayValueHigh <= 100 OR e.exp_assayValueHigh IS NULL)
),
/* 2.  Reactome physical entities corresponding to those targets        */
target_pe AS (
  SELECT DISTINCT pe.stable_id AS pe_id
  FROM  `isb-cgc-bq.reactome_versioned.physical_entity_v77` AS pe
  JOIN  sorafenib_targets AS st
         ON pe.uniprot_id = st.target_uniprotID
),
/* 3.  Universe = every PE found (via TAS) in any lowest-level
        Homo sapiens pathway                                           */
universe AS (
  SELECT DISTINCT p2p.pe_stable_id AS pe_id
  FROM  `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` AS p2p
  JOIN  `isb-cgc-bq.reactome_versioned.pathway_v77`       AS pv
         ON p2p.pathway_stable_id = pv.stable_id
  WHERE pv.species      = 'Homo sapiens'
    AND pv.lowest_level = TRUE
    AND p2p.evidence_code = 'TAS'
),
/* 4.  Totals needed for the 2×2 tables                                */
totals AS (
  SELECT
    COUNT(*)                                                AS universe_total,
    COUNTIF(pe_id IN  (SELECT pe_id FROM target_pe))        AS tgt_total,
    COUNTIF(pe_id NOT IN (SELECT pe_id FROM target_pe))     AS non_tgt_total
  FROM universe
),
/* 5.  PE-to-pathway mapping (restricted to same scope as ‘universe’)   */
pathway_pe AS (
  SELECT
    p2p.pathway_stable_id AS pathway_id,
    p2p.pe_stable_id      AS pe_id
  FROM  `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` AS p2p
  JOIN  `isb-cgc-bq.reactome_versioned.pathway_v77`       AS pv
         ON p2p.pathway_stable_id = pv.stable_id
  WHERE pv.species      = 'Homo sapiens'
    AND pv.lowest_level = TRUE
    AND p2p.evidence_code = 'TAS'
),
/* 6.  Build contingency-table counts for every pathway                 */
counts AS (
  SELECT
    pathway_id,
    COUNTIF(pe_id IN  (SELECT pe_id FROM target_pe))    AS a,  -- targets  in pathway
    COUNTIF(pe_id NOT IN (SELECT pe_id FROM target_pe)) AS c   -- non-tgt in pathway
  FROM pathway_pe
  GROUP BY pathway_id
),
stats AS (
  SELECT
    c.pathway_id,
    c.a,
    t.tgt_total      - c.a AS b,   -- targets    outside pathway
    c.c,
    t.non_tgt_total  - c.c AS d,   -- non-targets outside pathway
    t.universe_total       AS n
  FROM counts  AS c
  CROSS JOIN totals AS t
),
/* 7.  χ² statistic (1-degree of freedom)                               */
chi_sq AS (
  SELECT
    s.*,
    SAFE_DIVIDE(
      POW((s.a * s.d) - (s.b * s.c), 2) * s.n,
      (s.a + s.b) * (s.c + s.d) * (s.a + s.c) * (s.b + s.d)
    ) AS chi_val
  FROM stats AS s
)
SELECT
  cs.pathway_id,
  pv.name,
  cs.a AS in_targets,
  cs.b AS out_targets,
  cs.c AS in_non_targets,
  cs.d AS out_non_targets,
  cs.chi_val AS chi_squared
FROM chi_sq AS cs
JOIN `isb-cgc-bq.reactome_versioned.pathway_v77` AS pv
  ON cs.pathway_id = pv.stable_id
ORDER BY chi_squared DESC
LIMIT 3;