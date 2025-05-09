-- top 3 lowest‑level Reactome (TAS) pathways most enriched for
-- Homo sapiens sorafenib targets (assay median ≤100 nM and
-- low / high ≤100 nM or null).  Returns the 2×2 table counts
-- together with the chi‑square statistic.

WITH
/*--------------- 1. Sorafenib targets that meet assay constraints -----------*/
soraf_targets AS (
  SELECT DISTINCT i.target_uniprotID AS uniprot_id
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1` AS i
  JOIN `isb-cgc-bq.targetome_versioned.experiments_v1`        AS e
    ON i.expID = e.expID
  WHERE LOWER(i.drugName) LIKE '%sorafenib%'                 -- the drug
    AND i.targetSpecies = 'Homo sapiens'                     -- species
    AND e.exp_assayValueMedian  <= 100
    AND (e.exp_assayValueLow   <= 100 OR e.exp_assayValueLow   IS NULL)
    AND (e.exp_assayValueHigh  <= 100 OR e.exp_assayValueHigh  IS NULL)
    AND i.target_uniprotID IS NOT NULL
),

/*--------------- 2. Universe of Homo sapiens targets ------------------------*/
all_targets AS (
  SELECT DISTINCT target_uniprotID AS uniprot_id
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1`
  WHERE targetSpecies = 'Homo sapiens'
    AND target_uniprotID IS NOT NULL
),

universe_counts AS (
  SELECT
    (SELECT COUNT(*) FROM soraf_targets)                                              AS num_targets,
    (SELECT COUNT(*) FROM all_targets WHERE uniprot_id NOT IN (SELECT uniprot_id
                                                                FROM soraf_targets))  AS num_non_targets
),

/*--------------- 3. Members (UniProt IDs) of each lowest‑level TAS pathway --*/
pathway_members AS (
  SELECT DISTINCT
    p2p.pathway_stable_id                 AS pathway_id,
    pe.uniprot_id
  FROM `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77`  AS p2p
  JOIN `isb-cgc-bq.reactome_versioned.physical_entity_v77` AS pe
    ON p2p.pe_stable_id = pe.stable_id
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77`         AS pw
    ON p2p.pathway_stable_id = pw.stable_id
  WHERE p2p.evidence_code = 'TAS'          -- TAS evidence
    AND pw.lowest_level  = TRUE            -- lowest level pathway
    AND pw.species       = 'Homo sapiens'  -- species
    AND pe.uniprot_id IS NOT NULL
),

/*--------------- 4. Count targets / members per pathway --------------------*/
pathway_stats AS (
  SELECT
    pm.pathway_id,
    COUNT(DISTINCT CASE WHEN st.uniprot_id IS NOT NULL THEN pm.uniprot_id END)
        AS targets_in_pathway,
    COUNT(DISTINCT pm.uniprot_id)                       AS total_in_pathway
  FROM pathway_members pm
  LEFT JOIN soraf_targets st
    ON pm.uniprot_id = st.uniprot_id
  GROUP BY pm.pathway_id
),

/*--------------- 5. Build full 2×2 table & chi‑square ----------------------*/
combined AS (
  SELECT
    ps.pathway_id,
    pw.name                                            AS pathway_name,
    ps.targets_in_pathway                              AS targets_in_pathway,
    (uc.num_targets - ps.targets_in_pathway)           AS targets_not_in_pathway,
    (ps.total_in_pathway - ps.targets_in_pathway)      AS non_targets_in_pathway,
    (uc.num_non_targets -
       (ps.total_in_pathway - ps.targets_in_pathway))  AS non_targets_not_in_pathway,
    uc.num_targets,
    uc.num_non_targets
  FROM pathway_stats ps
  JOIN universe_counts uc ON TRUE
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77` pw
    ON pw.stable_id = ps.pathway_id
),

chi2_calc AS (
  SELECT
    *,
    SAFE_DIVIDE(
      POW( (targets_in_pathway * non_targets_not_in_pathway) -
           (targets_not_in_pathway * non_targets_in_pathway), 2 )
      * (num_targets + num_non_targets),
      num_targets * num_non_targets *
      (targets_in_pathway + non_targets_in_pathway) *
      (targets_not_in_pathway + non_targets_not_in_pathway)
    ) AS chi2_stat
  FROM combined
  -- avoid divisions where any expected cell is zero
  WHERE targets_in_pathway   + non_targets_in_pathway   > 0
    AND targets_not_in_pathway + non_targets_not_in_pathway > 0
)

/*--------------- 6. Return the three most significant pathways -------------*/
SELECT
  pathway_id,
  pathway_name,
  targets_in_pathway,
  targets_not_in_pathway,
  non_targets_in_pathway,
  non_targets_not_in_pathway,
  chi2_stat
FROM chi2_calc
ORDER BY chi2_stat DESC
LIMIT 3;