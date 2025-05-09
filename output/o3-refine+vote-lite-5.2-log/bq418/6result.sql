--  Top 3 lowest–level Reactome pathways (TAS evidence) whose protein membership
--  is most enriched for Homo sapiens Sorafenib targets (median/low/high ≤ 100 nM)
--  Chi‑squared is calculated on a 2×2 table of
--      ( targets‑in , targets‑out , non‑targets‑in , non‑targets‑out )

WITH
/* ------------------------------------------------------------------- */
/* 1. Drug IDs that correspond to Sorafenib (name or any synonym)      */
sorafenib_drug_ids AS (
  SELECT DISTINCT drugID
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1`
  WHERE LOWER(drugName) LIKE '%sorafenib%'
  UNION DISTINCT
  SELECT DISTINCT drugID
  FROM `isb-cgc-bq.targetome_versioned.drug_synonyms_v1`
  WHERE LOWER(synonym) LIKE '%sorafenib%'
),

/* ------------------------------------------------------------------- */
/* 2. Sorafenib targets that satisfy the assay‑value criteria          */
sorafenib_targets AS (
  SELECT DISTINCT i.target_uniprotID AS uniprot_id
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1`  AS i
  JOIN sorafenib_drug_ids                                   USING (drugID)
  JOIN `isb-cgc-bq.targetome_versioned.experiments_v1`  AS e
        ON e.expID = i.expID
  WHERE i.targetSpecies         = 'Homo sapiens'
    AND i.target_uniprotID IS NOT NULL
    AND e.exp_assayValueMedian <= 100
    AND (e.exp_assayValueLow  <= 100 OR e.exp_assayValueLow  IS NULL)
    AND (e.exp_assayValueHigh <= 100 OR e.exp_assayValueHigh IS NULL)
),

/* ------------------------------------------------------------------- */
/* 3. Mapping of (uniprot ↔ lowest‑level Homo sapiens pathway) with TAS */
pathway_mapping AS (
  SELECT DISTINCT
         pe.uniprot_id,
         p2p.pathway_stable_id AS pathway_id
  FROM `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77`     AS p2p
  JOIN `isb-cgc-bq.reactome_versioned.physical_entity_v77`   AS pe
       ON pe.stable_id = p2p.pe_stable_id
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77`           AS pw
       ON pw.stable_id = p2p.pathway_stable_id
  WHERE p2p.evidence_code = 'TAS'
    AND pw.lowest_level   = TRUE
    AND pw.species        = 'Homo sapiens'
    AND pe.uniprot_id     IS NOT NULL
),

/* ------------------------------------------------------------------- */
/* 4. Universe of proteins considered (all those in any such pathway)  */
universe AS (
  SELECT DISTINCT uniprot_id FROM pathway_mapping
),

/* ------------------------------------------------------------------- */
/* 5. Pre‑compute pathway‑level counts (deduplicated on uniprot)       */
pathway_counts AS (
  SELECT
    pm.pathway_id,
    COUNTIF(st.uniprot_id IS NOT NULL) AS targets_in,
    COUNTIF(st.uniprot_id IS NULL)     AS non_targets_in
  FROM (
        SELECT DISTINCT pathway_id, uniprot_id
        FROM pathway_mapping
       ) AS pm
  LEFT JOIN sorafenib_targets st
         ON pm.uniprot_id = st.uniprot_id
  GROUP BY pathway_id
),

/* ------------------------------------------------------------------- */
/* 6. Totals needed for chi‑square computation                         */
totals AS (
  SELECT
    (SELECT COUNT(*)  FROM sorafenib_targets) AS total_targets,
    (SELECT COUNT(*)  FROM universe)          AS total_universe
),

/* ------------------------------------------------------------------- */
/* 7. Chi‑square for each pathway                                      */
chi_sq AS (
  SELECT
    pc.pathway_id,
    pc.targets_in                                   AS targets_in_pathway,
    (tot.total_targets - pc.targets_in)             AS targets_outside_pathway,
    pc.non_targets_in                               AS non_targets_in_pathway,
    ( (tot.total_universe - tot.total_targets)
        - pc.non_targets_in )                       AS non_targets_outside_pathway,
    SAFE_DIVIDE(                                    -- chi‑square (1 d.f.)
      tot.total_universe
        * POW( (pc.targets_in
                   * ( (tot.total_universe - tot.total_targets)
                         - pc.non_targets_in )
                 )
               - ( (tot.total_targets - pc.targets_in)
                     * pc.non_targets_in ), 2),
      (pc.targets_in + pc.non_targets_in)
      * ( (tot.total_targets - pc.targets_in)
            + ( (tot.total_universe - tot.total_targets)
                  - pc.non_targets_in ) )
      * (pc.targets_in + (tot.total_targets - pc.targets_in))
      * (pc.non_targets_in
           + ( (tot.total_universe - tot.total_targets)
                 - pc.non_targets_in ) ) )          AS chi_squared
  FROM pathway_counts pc
  CROSS JOIN totals tot
)

/* ------------------------------------------------------------------- */
/* 8. Return the three pathways with the highest chi‑square            */
SELECT
  cs.pathway_id                   AS reactome_pathway_id,
  pw.name                         AS pathway_name,
  cs.targets_in_pathway,
  cs.targets_outside_pathway,
  cs.non_targets_in_pathway,
  cs.non_targets_outside_pathway,
  cs.chi_squared
FROM chi_sq               AS cs
JOIN `isb-cgc-bq.reactome_versioned.pathway_v77` AS pw
  ON pw.stable_id = cs.pathway_id
ORDER BY cs.chi_squared DESC
LIMIT 3;