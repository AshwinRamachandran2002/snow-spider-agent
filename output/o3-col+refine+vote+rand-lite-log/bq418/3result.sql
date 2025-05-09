/*  Top-3 lowest-level Reactome pathways (TAS evidence, Homo sapiens) that are
    most enriched for sorafenib targets with high-confidence (≤ 100 nM) binding   */

WITH
-- 1. Sorafenib drug identifiers -------------------------------------------------
sorafenib_drug AS (
  SELECT DISTINCT `drugID`
  FROM `isb-cgc-bq.targetome_versioned.drug_synonyms_v1`
  WHERE LOWER(`synonym`) LIKE '%sorafenib%'
),

-- 2. UniProt IDs of high-confidence sorafenib targets (median ≤ 100 nM) ---------
sorafenib_targets AS (
  SELECT DISTINCT i.`target_uniprotID`
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1` AS i
  JOIN `isb-cgc-bq.targetome_versioned.experiments_v1`  AS e
    ON i.`expID` = e.`expID`
  WHERE i.`drugID` IN (SELECT `drugID` FROM sorafenib_drug)
    AND e.`exp_assayUnits` = 'nM'
    AND e.`exp_assayValueMedian` <= 100
    AND (e.`exp_assayValueLow`  IS NULL OR e.`exp_assayValueLow`  <= 100)
    AND (e.`exp_assayValueHigh` IS NULL OR e.`exp_assayValueHigh` <= 100)
),

-- 3. Reactome physical-entity (PE) IDs for those targets ------------------------
target_pe AS (
  SELECT DISTINCT `stable_id` AS pe_id
  FROM `isb-cgc-bq.reactome_versioned.physical_entity_v77`
  WHERE `uniprot_id` IN (SELECT `target_uniprotID` FROM sorafenib_targets)
),

-- 4. Background = all PEs that have TAS links to lowest-level human pathways ----
background_pe AS (
  SELECT DISTINCT ptp.`pe_stable_id` AS pe_id
  FROM `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` AS ptp
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77`       AS pw
    ON ptp.`pathway_stable_id` = pw.`stable_id`
  WHERE ptp.`evidence_code` = 'TAS'
    AND pw.`lowest_level` = TRUE
    AND pw.`species`      = 'Homo sapiens'
),
non_target_pe AS (
  SELECT pe_id
  FROM background_pe
  WHERE pe_id NOT IN (SELECT pe_id FROM target_pe)
),

-- 5. Map every background PE to its pathways (TAS, lowest-level, human) ---------
map_all AS (
  SELECT DISTINCT ptp.`pathway_stable_id` AS pathway_id,
         ptp.`pe_stable_id`               AS pe_id
  FROM `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` AS ptp
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77`       AS pw
    ON ptp.`pathway_stable_id` = pw.`stable_id`
  WHERE ptp.`evidence_code` = 'TAS'
    AND pw.`lowest_level`   = TRUE
    AND pw.`species`        = 'Homo sapiens'
),

-- 6. 2×2 table counts for every pathway ----------------------------------------
pathway_counts AS (
  SELECT
    pw.`stable_id` AS pathway_id,
    pw.`name`      AS pathway_name,
    COUNTIF(pe_id IN (SELECT pe_id FROM target_pe))     AS targets_in,
    COUNTIF(pe_id IN (SELECT pe_id FROM non_target_pe)) AS nontargets_in
  FROM map_all
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77` AS pw
    ON map_all.pathway_id = pw.`stable_id`
  GROUP BY pathway_id, pathway_name
),

totals AS (
  SELECT
    (SELECT COUNT(*) FROM target_pe)     AS T,
    (SELECT COUNT(*) FROM non_target_pe) AS N
),

-- 7. Chi-squared statistic for each pathway ------------------------------------
final AS (
  SELECT
    pc.pathway_id,
    pc.pathway_name,
    pc.targets_in,
    (tot.T - pc.targets_in)        AS targets_out,
    pc.nontargets_in,
    (tot.N - pc.nontargets_in)     AS nontargets_out,
    (
      POW( (pc.targets_in * (tot.N - pc.nontargets_in)) -
           (pc.nontargets_in * (tot.T - pc.targets_in)), 2 )
      /
      (CAST(tot.T AS FLOAT64) * tot.N *
       (pc.targets_in + pc.nontargets_in) *
       ((tot.T - pc.targets_in) + (tot.N - pc.nontargets_in))
      )
    )                              AS chi_squared
  FROM pathway_counts AS pc
  CROSS JOIN totals AS tot
)

-- 8. Return the three pathways with the highest chi-squared --------------------
SELECT
  pathway_id,
  pathway_name,
  targets_in,
  targets_out,
  nontargets_in,
  nontargets_out,
  chi_squared
FROM final
ORDER BY chi_squared DESC
LIMIT 3;