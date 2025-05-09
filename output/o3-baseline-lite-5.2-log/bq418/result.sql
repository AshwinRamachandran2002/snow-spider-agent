/*  TOP‑3 lowest‑level Reactome pathways (TAS evidence) that are most
    strongly enriched for Homo sapiens sorafenib targets (KD/IC50/… ≤100 nM)

    For every pathway we return the 2×2 contingency‑table counts that were
    used to compute the chi‑squared statistic:

         ┌───────────────────────┬─────────────────┐
         │                       │   In pathway    │   Out of pathway
         ├───────────────────────┼─────────────────┼───────────────────┤
         │  Sorafenib target     │       A         │        B
         │  Non‑target           │       C         │        D
         └───────────────────────┴─────────────────┴───────────────────┘
*/
WITH
/* 1. All Targetome drugIDs that correspond to sorafenib               */
sorafenib_drug_ids AS (
  SELECT DISTINCT drugID
  FROM `isb-cgc-bq.targetome_versioned.drug_synonyms_v1`
  WHERE LOWER(synonym) LIKE '%sorafenib%'
),
/* 2. Sorafenib–target interactions that satisfy the potency filter    */
sorafenib_targets AS (
  SELECT DISTINCT i.target_uniprotID
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1`   AS i
  JOIN sorafenib_drug_ids                                  USING (drugID)
  JOIN `isb-cgc-bq.targetome_versioned.experiments_v1` AS e
    ON i.expID = e.expID
  WHERE i.targetSpecies = 'Homo sapiens'
    AND e.exp_assayValueMedian <= 100
    AND (e.exp_assayValueLow  <= 100 OR e.exp_assayValueLow  IS NULL)
    AND (e.exp_assayValueHigh <= 100 OR e.exp_assayValueHigh IS NULL)
),
/* 3. Reactome physical‑entity stable IDs corresponding to those       */
pe_targets AS (
  SELECT DISTINCT pe.stable_id AS pe_stable_id
  FROM sorafenib_targets t
  JOIN `isb-cgc-bq.reactome_versioned.physical_entity_v77` pe
    ON pe.uniprot_id = t.target_uniprotID
),
/* 4. Physical‑entity ↔ pathway links that have TAS evidence and point
      to lowest‑level human pathways                                   */
pe_pathways AS (
  SELECT DISTINCT p2.stable_id      AS pathway_id,
         peTo.pe_stable_id          AS pe_stable_id
  FROM `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` peTo
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77`      p2
       ON p2.stable_id = peTo.pathway_stable_id
  WHERE peTo.evidence_code = 'TAS'
    AND p2.lowest_level   = TRUE
    AND p2.species        = 'Homo sapiens'
),
/* 5. Universe of all physical entities occurring in those pathways    */
all_pe_in_tas_paths AS (
  SELECT DISTINCT pe_stable_id
  FROM pe_pathways
),
/* 6. For every pathway, count targets‑in, non‑targets‑in              */
counts AS (
  SELECT
    pathway_id,
    COUNT(DISTINCT IF(pt.pe_stable_id IS NOT NULL, pp.pe_stable_id, NULL))  AS targets_in_path,
    COUNT(DISTINCT pp.pe_stable_id)                                         -
    COUNT(DISTINCT IF(pt.pe_stable_id IS NOT NULL, pp.pe_stable_id, NULL))  AS nontargets_in_path
  FROM pe_pathways pp
  LEFT JOIN pe_targets pt
         ON pt.pe_stable_id = pp.pe_stable_id
  GROUP BY pathway_id
),
/* 7. Totals for the whole universe                                    */
totals AS (
  SELECT
    (SELECT COUNT(DISTINCT pe_stable_id) FROM pe_targets)          AS total_targets,
    (SELECT COUNT(DISTINCT pe_stable_id) FROM all_pe_in_tas_paths) -
    (SELECT COUNT(DISTINCT pe_stable_id) FROM pe_targets)          AS total_nontargets
),
/* 8. Chi‑square calculation                                           */
chi2_calc AS (
  SELECT
    c.pathway_id,
    c.targets_in_path                               AS A,
    (t.total_targets    - c.targets_in_path)        AS B,
    c.nontargets_in_path                           AS C,
    (t.total_nontargets - c.nontargets_in_path)     AS D,
    SAFE_DIVIDE(
      (t.total_targets + t.total_nontargets)
      * POW((c.targets_in_path * (t.total_nontargets - c.nontargets_in_path)
            - (t.total_targets - c.targets_in_path) * c.nontargets_in_path), 2),
      t.total_targets * t.total_nontargets
      * (c.targets_in_path + c.nontargets_in_path)
      * ((t.total_targets + t.total_nontargets)
         - (c.targets_in_path + c.nontargets_in_path))
    ) AS chi2
  FROM counts c
  CROSS JOIN totals t
  WHERE t.total_targets > 0     -- safeguard against division by zero
    AND t.total_nontargets > 0
)
/* 9. Return the three pathways with the highest chi‑square statistic  */
SELECT
  chi.pathway_id                    AS pathway_stable_id,
  p.name                            AS pathway_name,
  chi.A                             AS targets_in_path,
  chi.B                             AS targets_out_of_path,
  chi.C                             AS nontargets_in_path,
  chi.D                             AS nontargets_out_of_path
FROM chi2_calc chi
JOIN `isb-cgc-bq.reactome_versioned.pathway_v77` p
  ON p.stable_id = chi.pathway_id
ORDER BY chi.chi2 DESC
LIMIT 3;