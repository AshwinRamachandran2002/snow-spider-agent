/* -----------------------------------------------------------
   Top-3 lowest-level Reactome pathways (TAS evidence only)
   that are most enriched for potent (≤ 100 nM) Homo-sapiens
   sorafenib targets.  The query returns the χ² statistic and
   the four contingency-table counts:

        A = # potent sorafenib targets inside the pathway
        B = # potent sorafenib targets outside the pathway
        C = # non-targets (other PEs)  inside the pathway
        D = # non-targets outside the pathway
   ----------------------------------------------------------- */
WITH
-- 1.  All Targetome drugIDs that are aliased as “sorafenib”
drug_ids AS (
  SELECT DISTINCT drugID
  FROM `isb-cgc-bq.targetome_versioned.drug_synonyms_v1`
  WHERE LOWER(synonym) LIKE '%sorafenib%'
),

-- 2.  Potent (≤100 nM) Homo-sapiens interactions for those drugs
valid_interactions AS (
  SELECT DISTINCT i.target_uniprotID
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1`  AS i
  JOIN `isb-cgc-bq.targetome_versioned.experiments_v1`   AS e
    ON i.expID = e.expID
  WHERE i.drugID IN (SELECT drugID FROM drug_ids)
    AND i.targetSpecies = 'Homo sapiens'
    AND (e.exp_assayUnits IS NULL OR LOWER(e.exp_assayUnits) = 'nm')
    AND (e.exp_assayValueMedian <= 100 OR e.exp_assayValueMedian IS NULL)
    AND (e.exp_assayValueLow    <= 100 OR e.exp_assayValueLow   IS NULL)
    AND (e.exp_assayValueHigh   <= 100 OR e.exp_assayValueHigh  IS NULL)
    AND i.target_uniprotID IS NOT NULL
),

-- 3.  Reactome physical-entity IDs corresponding to those UniProts
targets AS (
  SELECT DISTINCT p.stable_id AS pe_stable_id
  FROM `isb-cgc-bq.reactome_versioned.physical_entity_v77` AS p
  JOIN valid_interactions                                   v
    ON p.uniprot_id = v.target_uniprotID
),

-- 4.  TAS-supported PE ↔ pathway mappings
pm AS (
  SELECT DISTINCT ptp.pathway_stable_id, ptp.pe_stable_id
  FROM `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` AS ptp
  WHERE ptp.evidence_code = 'TAS'
),

-- 5.  Universe of all physical entities appearing in TAS mappings
all_entities AS (
  SELECT DISTINCT pe_stable_id FROM pm
),

-- 6.  Lowest-level Reactome pathways
lowest_pathways AS (
  SELECT stable_id
  FROM `isb-cgc-bq.reactome_versioned.pathway_v77`
  WHERE lowest_level = TRUE
),

-- 7.  Build contingency-table counts for each lowest-level pathway
counts AS (
  SELECT
    lp.stable_id AS pathway_id,

    -- A: targets inside the pathway
    COUNT(DISTINCT CASE WHEN t.pe_stable_id IS NOT NULL THEN pm.pe_stable_id END) AS A,

    -- B: targets outside the pathway
    (SELECT COUNT(*) FROM targets)
      - COUNT(DISTINCT CASE WHEN t.pe_stable_id IS NOT NULL THEN pm.pe_stable_id END)          AS B,

    -- C: non-targets inside the pathway
    COUNT(DISTINCT CASE WHEN t.pe_stable_id IS NULL THEN pm.pe_stable_id END)                  AS C,

    -- D: non-targets outside the pathway
    (SELECT COUNT(*) FROM all_entities)
      - COUNT(DISTINCT pm.pe_stable_id)
      - ((SELECT COUNT(*) FROM targets)
         - COUNT(DISTINCT CASE WHEN t.pe_stable_id IS NOT NULL THEN pm.pe_stable_id END))      AS D
  FROM lowest_pathways lp
  LEFT JOIN pm      ON lp.stable_id      = pm.pathway_stable_id
  LEFT JOIN targets t ON t.pe_stable_id  = pm.pe_stable_id
  GROUP BY lp.stable_id
),

-- 8.  χ² statistic for every pathway
chi_sq AS (
  SELECT
    c.*,
    SAFE_DIVIDE( (c.A + c.B + c.C + c.D) * POW((c.A * c.D - c.B * c.C), 2),
                 (c.A + c.B) * (c.C + c.D) * (c.A + c.C) * (c.B + c.D) ) AS chi_squared
  FROM counts c
)

-- 9.  Final result: top-3 pathways with the highest χ²
SELECT
  cs.pathway_id                                    AS pathway_stable_id,
  pw.name                                          AS pathway_name,
  cs.A                                             AS targets_in,
  cs.B                                             AS targets_out,
  cs.C                                             AS nontargets_in,
  cs.D                                             AS nontargets_out,
  cs.chi_squared
FROM chi_sq             cs
JOIN `isb-cgc-bq.reactome_versioned.pathway_v77` pw
  ON pw.stable_id = cs.pathway_id
ORDER BY cs.chi_squared DESC
LIMIT 3;