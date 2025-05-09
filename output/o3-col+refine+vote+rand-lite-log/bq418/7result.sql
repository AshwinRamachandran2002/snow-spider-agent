WITH
-- 1)  Sorafenib drug-IDs
sorafenib_drug AS (
  SELECT DISTINCT drugID
  FROM `isb-cgc-bq.targetome_versioned.drug_synonyms_v1`
  WHERE LOWER(synonym) LIKE '%sorafenib%'
),

-- 2)  Potent Homo sapiens UniProt targets of sorafenib
potent_uniprot AS (
  SELECT DISTINCT i.target_uniprotID
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1` i
  JOIN `isb-cgc-bq.targetome_versioned.experiments_v1`  e
    ON i.expID = e.expID
  WHERE i.drugID IN (SELECT drugID FROM sorafenib_drug)
    AND LOWER(i.targetSpecies) = 'homo sapiens'
    AND e.exp_assayValueMedian <= 100
    AND (e.exp_assayValueLow  IS NULL OR e.exp_assayValueLow  <= 100)
    AND (e.exp_assayValueHigh IS NULL OR e.exp_assayValueHigh <= 100)
),

-- 3)  Reactome Physical Entities (PEs) for those UniProt IDs
sorafenib_pe AS (
  SELECT DISTINCT pe.stable_id AS pe_id
  FROM `isb-cgc-bq.reactome_versioned.physical_entity_v77` pe
  JOIN potent_uniprot u
    ON LOWER(pe.uniprot_id) = LOWER(u.target_uniprotID)
),

-- 4)  TAS-evidence links between PEs and lowest-level pathways
tas_links AS (
  SELECT DISTINCT ptp.pe_stable_id   AS pe_id,
                  ptp.pathway_stable_id AS pathway_id
  FROM `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` ptp
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77`       pw
    ON pw.stable_id = ptp.pathway_stable_id
  WHERE ptp.evidence_code = 'TAS'
    AND pw.lowest_level   = TRUE
),

-- 5)  Global totals needed for the 2×2 tables
tas_pe AS (SELECT DISTINCT pe_id FROM tas_links),
totals AS (
  SELECT
    (SELECT COUNT(*) FROM sorafenib_pe) AS total_targets,
    (SELECT COUNT(*) FROM tas_pe)       AS total_pe
),

-- 6)  For every pathway: count targets-inside (A) and total-inside
pathway_stats AS (
  SELECT
    pw.stable_id AS pathway_id,
    pw.name      AS pathway_name,
    COUNT(DISTINCT CASE WHEN sp.pe_id IS NOT NULL THEN tl.pe_id END) AS A,
    COUNT(DISTINCT tl.pe_id)                                         AS total_in
  FROM tas_links tl
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77` pw
    ON pw.stable_id = tl.pathway_id
  LEFT JOIN sorafenib_pe sp
    ON sp.pe_id = tl.pe_id
  GROUP BY pw.stable_id, pw.name
  HAVING A > 0                                    -- pathway must contain ≥1 target
),

-- 7)  Build complete 2×2 tables and χ² for each pathway
chi_calc AS (
  SELECT
    ps.pathway_id,
    ps.pathway_name,
    ps.A                                                      AS targets_in,        -- A
    (tot.total_targets - ps.A)                                AS targets_out,       -- B
    (ps.total_in - ps.A)                                      AS nontargets_in,     -- C
    ((tot.total_pe - tot.total_targets) - (ps.total_in - ps.A)) AS nontargets_out,  -- D
    -- χ²  =  N(AD−BC)² / ((A+B)(C+D)(A+C)(B+D)),  where N = A+B+C+D = total_pe
    ( tot.total_pe *
      POW( (ps.A * ((tot.total_pe - tot.total_targets) - (ps.total_in - ps.A))
           - (tot.total_targets - ps.A) * (ps.total_in - ps.A) ), 2 )
    )
    /
    ( (ps.A + (tot.total_targets - ps.A)) *
      ((ps.total_in - ps.A) + ((tot.total_pe - tot.total_targets) - (ps.total_in - ps.A))) *
      (ps.A + (ps.total_in - ps.A)) *
      ((tot.total_targets - ps.A) + ((tot.total_pe - tot.total_targets) - (ps.total_in - ps.A))) )
      AS chi_sq
  FROM pathway_stats ps
  CROSS JOIN totals tot
),

-- 8)  Rank pathways by χ² and select the top-3
ranked AS (
  SELECT *,
         ROW_NUMBER() OVER (ORDER BY chi_sq DESC) AS rk
  FROM chi_calc
)

-- 9)  Final answer
SELECT
  pathway_id,
  pathway_name,
  targets_in      AS A,
  targets_out     AS B,
  nontargets_in   AS C,
  nontargets_out  AS D,
  chi_sq
FROM ranked
WHERE rk <= 3
ORDER BY chi_sq DESC;