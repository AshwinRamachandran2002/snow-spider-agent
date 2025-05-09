-- Top 3 lowest‑level Homo sapiens Reactome pathways (TAS evidence) with highest
-- χ² statistic in relation to Sorafenib human targets (median ≤100 nM and
-- low/high ≤100 nM or NULL)
WITH
/* -------------------------------------------------------------------------- */
/* Sorafenib human targets that satisfy the potency constraints               */
sorafenib_targets AS (
  SELECT DISTINCT
         i.target_uniprotID   AS uniprot_id
  FROM  `isb-cgc-bq.targetome_versioned.interactions_v1`  AS i
  JOIN  `isb-cgc-bq.targetome_versioned.experiments_v1`   AS e
        ON  i.expID = e.expID
  WHERE LOWER(i.drugName)            LIKE 'sorafenib%'          -- drug = sorafenib
    AND i.targetSpecies              = 'Homo sapiens'           -- human targets
    AND e.exp_assayValueMedian      <= 100                      -- potency filters
    AND (e.exp_assayValueLow  IS NULL OR e.exp_assayValueLow  <= 100)
    AND (e.exp_assayValueHigh IS NULL OR e.exp_assayValueHigh <= 100)
),
/* -------------------------------------------------------------------------- */
/* Map those UniProt IDs to Reactome physical entities (PEs)                  */
target_pe AS (
  SELECT DISTINCT
         p.stable_id AS pe_id
  FROM  sorafenib_targets                          t
  JOIN  `isb-cgc-bq.reactome_versioned.physical_entity_v77` p
        ON p.uniprot_id = t.uniprot_id
),
/* -------------------------------------------------------------------------- */
/* Background = every PE that is in a lowest‑level human pathway via TAS       */
background_pe AS (
  SELECT DISTINCT
         m.pe_stable_id AS pe_id
  FROM  `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` m
  JOIN  `isb-cgc-bq.reactome_versioned.pathway_v77`       pw
        ON pw.stable_id = m.pathway_stable_id
  WHERE m.evidence_code = 'TAS'
    AND pw.species      = 'Homo sapiens'
    AND pw.lowest_level = TRUE
),
totals AS (
  SELECT
    (SELECT COUNT(DISTINCT pe_id) FROM target_pe     ) AS total_targets,
    (SELECT COUNT(DISTINCT pe_id) FROM background_pe ) AS total_background
),
/* -------------------------------------------------------------------------- */
/* For every candidate pathway, get target / non‑target counts inside         */
pathway_counts AS (
  SELECT
      pw.stable_id                              AS pathway_id,
      pw.name                                   AS pathway_name,
      COUNT(DISTINCT CASE WHEN tp.pe_id IS NOT NULL THEN m.pe_stable_id END) AS target_inside,
      COUNT(DISTINCT m.pe_stable_id)                                           AS total_inside
  FROM  `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77`  m
  JOIN  `isb-cgc-bq.reactome_versioned.pathway_v77`        pw
        ON pw.stable_id = m.pathway_stable_id
  LEFT JOIN target_pe                                      tp
        ON tp.pe_id = m.pe_stable_id
  WHERE m.evidence_code = 'TAS'
    AND pw.species      = 'Homo sapiens'
    AND pw.lowest_level = TRUE
  GROUP BY pathway_id, pathway_name
),
/* -------------------------------------------------------------------------- */
/* Assemble full 2×2 table and χ² statistic                                   */
chi_sq AS (
  SELECT
      pc.pathway_id,
      pc.pathway_name,
      pc.target_inside                                         AS targets_in_pathway,
      (pc.total_inside - pc.target_inside)                     AS nontargets_in_pathway,
      (t.total_targets   - pc.target_inside)                   AS targets_outside_pathway,
      ((t.total_background - t.total_targets)
         - (pc.total_inside - pc.target_inside))               AS nontargets_outside_pathway,
      -- χ² calculation: N(ad−bc)² / [(a+b)(c+d)(a+c)(b+d)]
      ( (t.total_background) *
        POW( (pc.target_inside *
              ((t.total_background - t.total_targets) -
               (pc.total_inside - pc.target_inside))
              ) -
             ( (t.total_targets - pc.target_inside) *
               (pc.total_inside - pc.target_inside)
             ), 2)
        ) /
        NULLIF( (t.total_targets) *
                (t.total_background - t.total_targets) *
                (pc.total_inside) *
                (t.total_background - pc.total_inside), 0)     AS chi_squared
  FROM pathway_counts pc
  CROSS JOIN totals t
)
SELECT
    pathway_id,
    pathway_name,
    targets_in_pathway,
    nontargets_in_pathway,
    targets_outside_pathway,
    nontargets_outside_pathway,
    chi_squared
FROM chi_sq
ORDER BY chi_squared DESC
LIMIT 3;