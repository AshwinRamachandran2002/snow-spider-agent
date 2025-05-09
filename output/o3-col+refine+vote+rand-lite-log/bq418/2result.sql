-- Top-3 lowest-level Reactome pathways (TAS evidence) most enriched for potent
-- Homo sapiens sorafenib targets, ranked by χ²
WITH sorafenib_targets AS (        -- UniProt targets that meet potency criteria
  SELECT DISTINCT LOWER(i.`target_uniprotID`) AS uniprot_id
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1`       i
  JOIN `isb-cgc-bq.targetome_versioned.drug_synonyms_v1`      s ON i.`drugID` = s.`drugID`
  JOIN `isb-cgc-bq.targetome_versioned.experiments_v1`        e ON i.`expID`  = e.`expID`
  WHERE LOWER(s.`synonym`) LIKE '%sorafenib%'
    AND LOWER(i.`targetSpecies`) = 'homo sapiens'
    AND e.`exp_assayValueMedian` <= 100
    AND (e.`exp_assayValueLow`  <= 100 OR e.`exp_assayValueLow`  IS NULL)
    AND (e.`exp_assayValueHigh` <= 100 OR e.`exp_assayValueHigh` IS NULL)
),
sorafenib_pe AS (          -- Reactome physical-entity IDs for those targets
  SELECT DISTINCT p.`stable_id` AS pe_stable_id
  FROM `isb-cgc-bq.reactome_versioned.physical_entity_v77` p
  JOIN sorafenib_targets t
    ON LOWER(p.`uniprot_id`) = t.`uniprot_id`
),
tas_pe_pathway AS (        -- TAS-supported PE ↔ pathway edges
  SELECT DISTINCT `pe_stable_id`, `pathway_stable_id`
  FROM `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77`
  WHERE `evidence_code` = 'TAS'
),
lowest_human_pathways AS ( -- Only lowest-level Homo sapiens pathways
  SELECT `stable_id`, `name`
  FROM `isb-cgc-bq.reactome_versioned.pathway_v77`
  WHERE `lowest_level` = TRUE
    AND `species` = 'Homo sapiens'
),
background_pe AS (         -- Universe of PEs with TAS evidence
  SELECT DISTINCT `pe_stable_id`
  FROM tas_pe_pathway
),
contingency AS (           -- Build a, b, c, d counts for every pathway
  SELECT
    lp.`stable_id` AS pathway_id,
    lp.`name`      AS pathway_name,
    SUM(CASE WHEN sp.`pe_stable_id` IS NOT NULL AND tp.`pe_stable_id` IS NOT NULL THEN 1 ELSE 0 END) AS a, -- targets in pathway
    SUM(CASE WHEN sp.`pe_stable_id` IS NOT NULL AND tp.`pe_stable_id` IS NULL  THEN 1 ELSE 0 END) AS b, -- targets outside pathway
    SUM(CASE WHEN sp.`pe_stable_id` IS NULL      AND tp.`pe_stable_id` IS NOT NULL THEN 1 ELSE 0 END) AS c, -- non-targets in pathway
    SUM(CASE WHEN sp.`pe_stable_id` IS NULL      AND tp.`pe_stable_id` IS NULL  THEN 1 ELSE 0 END) AS d  -- non-targets outside pathway
  FROM lowest_human_pathways lp
  CROSS JOIN background_pe pe
  LEFT JOIN tas_pe_pathway tp
    ON pe.`pe_stable_id` = tp.`pe_stable_id`
   AND tp.`pathway_stable_id` = lp.`stable_id`
  LEFT JOIN sorafenib_pe sp
    ON pe.`pe_stable_id` = sp.`pe_stable_id`
  GROUP BY pathway_id, pathway_name
),
chi2_scores AS (           -- χ² statistic (with SAFE_DIVIDE)
  SELECT
    pathway_id,
    pathway_name,
    a, b, c, d,
    SAFE_DIVIDE(
      (a+b+c+d) * POW(a*d - b*c, 2),
      (a+b) * (c+d) * (a+c) * (b+d)
    ) AS chi2
  FROM contingency
)
SELECT
  pathway_id,
  pathway_name,
  a AS targets_in_pathway,
  b AS targets_outside_pathway,
  c AS nontargets_in_pathway,
  d AS nontargets_outside_pathway,
  chi2
FROM chi2_scores
ORDER BY chi2 DESC
LIMIT 3;