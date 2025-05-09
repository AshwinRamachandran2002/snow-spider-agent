WITH
-- 1) sorafenib drugIDs ---------------------------------------------------------
sorafenib_drugs AS (
  -- drug name itself
  SELECT DISTINCT drugID
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1`
  WHERE LOWER(drugName) LIKE '%sorafenib%'
  UNION DISTINCT
  -- any synonym that contains “sorafenib”
  SELECT DISTINCT ds.drugID
  FROM `isb-cgc-bq.targetome_versioned.drug_synonyms_v1` ds
  WHERE LOWER(ds.synonym) LIKE '%sorafenib%'
),

-- 2) sorafenib → target interactions that satisfy the assay cut‑offs ----------
sorafenib_targets AS (
  SELECT DISTINCT i.target_uniprotID AS uniprot_id
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1` i
  JOIN sorafenib_drugs            sd  ON sd.drugID = i.drugID
  JOIN `isb-cgc-bq.targetome_versioned.experiments_v1` e
       ON e.expID = i.expID
  WHERE i.targetSpecies = 'Homo sapiens'
    AND i.target_uniprotID IS NOT NULL
    -- assay restrictions
    AND NOT IS_NAN(e.exp_assayValueMedian)            AND e.exp_assayValueMedian <= 100
    AND ( e.exp_assayValueLow  IS NULL OR (NOT IS_NAN(e.exp_assayValueLow)  AND e.exp_assayValueLow  <= 100) )
    AND ( e.exp_assayValueHigh IS NULL OR (NOT IS_NAN(e.exp_assayValueHigh) AND e.exp_assayValueHigh <= 100) )
),

-- 3) all human Targetome proteins (universe) ----------------------------------
all_human_targets AS (
  SELECT DISTINCT target_uniprotID AS uniprot_id
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1`
  WHERE targetSpecies = 'Homo sapiens'
    AND target_uniprotID IS NOT NULL
),

-- 4) non‑targets = universe minus sorafenib targets ---------------------------
non_targets AS (
  SELECT uniprot_id
  FROM all_human_targets
  WHERE uniprot_id NOT IN (SELECT uniprot_id FROM sorafenib_targets)
),

-- 5) label every protein as target / non‑target -------------------------------
protein_categories AS (
  SELECT uniprot_id, 'target'      AS category FROM sorafenib_targets
  UNION ALL
  SELECT uniprot_id, 'non_target'  AS category FROM non_targets
),

-- 6) lowest‑level Homo sapiens pathways ---------------------------------------
lowest_hs_pathways AS (
  SELECT stable_id, name
  FROM `isb-cgc-bq.reactome_versioned.pathway_v77`
  WHERE lowest_level = TRUE
    AND species = 'Homo sapiens'
),

-- 7) map proteins to pathways (TAS evidence only) -----------------------------
protein_pathway_map AS (
  SELECT DISTINCT
         pc.category,
         pc.uniprot_id,
         p2p.pathway_stable_id AS pathway_id
  FROM protein_categories                           pc
  JOIN `isb-cgc-bq.reactome_versioned.physical_entity_v77` pe
       ON pe.uniprot_id = pc.uniprot_id
  JOIN `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77`  p2p
       ON p2p.pe_stable_id = pe.stable_id
  JOIN lowest_hs_pathways          lp
       ON lp.stable_id = p2p.pathway_stable_id
  WHERE p2p.evidence_code = 'TAS'
),

-- 8) total counts of targets / non‑targets ------------------------------------
totals AS (
  SELECT
    (SELECT COUNT(*) FROM sorafenib_targets) AS total_targets,
    (SELECT COUNT(*) FROM non_targets)      AS total_non_targets
),

-- 9) per‑pathway counts --------------------------------------------------------
pathway_counts AS (
  SELECT
    lp.stable_id         AS pathway_id,
    lp.name              AS pathway_name,
    COUNT(DISTINCT CASE WHEN ppm.category = 'target'      THEN ppm.uniprot_id END) AS targets_in,
    COUNT(DISTINCT CASE WHEN ppm.category = 'non_target' THEN ppm.uniprot_id END) AS non_targets_in
  FROM lowest_hs_pathways lp
  LEFT JOIN protein_pathway_map ppm
         ON ppm.pathway_id = lp.stable_id
  GROUP BY pathway_id, pathway_name
),

-- 10) chi‑squared statistic ----------------------------------------------------
chi_squared_table AS (
  SELECT
    pc.pathway_id,
    pc.pathway_name,
    pc.targets_in,
    (t.total_targets   - pc.targets_in)    AS targets_out,
    pc.non_targets_in,
    (t.total_non_targets - pc.non_targets_in) AS non_targets_out,
    -- χ² = N(ad − bc)² / ((a+b)(c+d)(a+c)(b+d))
    SAFE_DIVIDE(
      (t.total_targets + t.total_non_targets) *
      POW( (pc.targets_in * (t.total_non_targets - pc.non_targets_in)
           - (t.total_targets - pc.targets_in) * pc.non_targets_in), 2 ),
      ( (pc.targets_in + (t.total_targets - pc.targets_in)) -- a+b
        * (pc.non_targets_in + (t.total_non_targets - pc.non_targets_in)) -- c+d
        * (pc.targets_in + pc.non_targets_in)              -- a+c
        * ( (t.total_targets - pc.targets_in) + (t.total_non_targets - pc.non_targets_in) ) -- b+d
      )
    ) AS chi_sq
  FROM pathway_counts pc
  CROSS JOIN totals t
)

-- 11) final answer: top 3 pathways by χ² --------------------------------------
SELECT
  pathway_id,
  pathway_name,
  targets_in,
  targets_out,
  non_targets_in,
  non_targets_out,
  chi_sq AS chi_squared_statistic
FROM chi_squared_table
ORDER BY chi_sq DESC
LIMIT 3;