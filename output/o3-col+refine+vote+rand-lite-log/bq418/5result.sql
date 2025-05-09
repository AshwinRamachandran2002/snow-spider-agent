/*  ──────────────────────────────────────────────────────────────────────────────
    Top-3 lowest-level Reactome pathways (TAS evidence) with the highest
    χ² statistics for potent (≤100 nM) Homo-sapiens Sorafenib targets.
    Returns, for each pathway:
        – # Sorafenib targets  IN   the pathway  (a)
        – # non-targets       IN   the pathway  (c)
        – # Sorafenib targets OUT  of pathway    (b)
        – # non-targets       OUT  of pathway    (d)
   ────────────────────────────────────────────────────────────────────────────── */
WITH
/* 1.  UniProt IDs of potent Sorafenib targets (Homo sapiens, ≤100 nM) */
soraf_target_uniprot AS (
  SELECT DISTINCT i.target_uniprotID
  FROM  `isb-cgc-bq.targetome_versioned.interactions_v1`  AS i
  JOIN  `isb-cgc-bq.targetome_versioned.drug_synonyms_v1` AS d
         ON i.drugID = d.drugID
  JOIN  `isb-cgc-bq.targetome_versioned.experiments_v1`   AS e
         ON i.expID = e.expID
  WHERE LOWER(d.synonym)       LIKE '%sorafenib%'
    AND LOWER(i.targetSpecies) = 'homo sapiens'
    AND e.exp_assayValueMedian <= 100
    AND (e.exp_assayValueLow  <= 100 OR e.exp_assayValueLow  IS NULL)
    AND (e.exp_assayValueHigh <= 100 OR e.exp_assayValueHigh IS NULL)
),

/* 2.  Corresponding Reactome physical entities (PEs) */
soraf_pe AS (
  SELECT DISTINCT p.stable_id AS pe_stable_id
  FROM `isb-cgc-bq.reactome_versioned.physical_entity_v77` AS p
  JOIN soraf_target_uniprot u
    ON p.uniprot_id = u.target_uniprotID
),

/* 3.  PE-to-pathway links that are:
        – TAS evidence
        – lowest-level
        – Homo-sapiens pathway                                         */
path_pe AS (
  SELECT pep.pathway_stable_id,
         pep.pe_stable_id
  FROM `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77` AS pep
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77`       AS pw
    ON pep.pathway_stable_id = pw.stable_id
  WHERE pep.evidence_code = 'TAS'
    AND pw.lowest_level   = TRUE
    AND LOWER(pw.species) = 'homo sapiens'
),

/* 4.  Universe of all PEs appearing in any such pathway */
universe AS (
  SELECT DISTINCT pe_stable_id FROM path_pe
),

/* 5.  Global totals needed for χ² calculation */
totals AS (
  SELECT
    COUNT(DISTINCT pe_stable_id)                     AS total_universe,
    (SELECT COUNT(*) FROM soraf_pe)                 AS total_target,
    COUNT(DISTINCT pe_stable_id)
      - (SELECT COUNT(*) FROM soraf_pe)             AS total_non_target
  FROM universe
),

/* 6.  For every pathway:  a = targets-in-path,  total_in_path = a + c       */
path_counts AS (
  SELECT
    p.pathway_stable_id                    AS pathway_id,
    COUNT(DISTINCT CASE
                     WHEN s.pe_stable_id IS NOT NULL
                     THEN p.pe_stable_id
                   END)                   AS targets_in_path,            -- a
    COUNT(DISTINCT p.pe_stable_id)         AS total_in_path              -- a + c
  FROM path_pe p
  LEFT JOIN soraf_pe s
         ON p.pe_stable_id = s.pe_stable_id
  GROUP BY pathway_id
),

/* 7.  Build contingency table & χ² for each pathway                       */
chi2_calc AS (
  SELECT
    pc.pathway_id,
    pc.targets_in_path                                       AS a,
    (t.total_target     - pc.targets_in_path)                AS b,
    (pc.total_in_path   - pc.targets_in_path)                AS c,
    (t.total_non_target - (pc.total_in_path - pc.targets_in_path)) AS d,
    -- χ² (1-df) for 2×2 table:  N*(ad−bc)² / ((a+b)(c+d)(a+c)(b+d))
    ( CAST(t.total_universe AS FLOAT64)
      * POW( (pc.targets_in_path
              * (t.total_non_target - (pc.total_in_path - pc.targets_in_path))
              )
            - ( (t.total_target - pc.targets_in_path)
                * (pc.total_in_path - pc.targets_in_path) ),
             2
           )
    )
    / NULLIF( (t.total_target)
              * (t.total_non_target)
              * pc.total_in_path
              * (t.total_universe - pc.total_in_path), 0)      AS chi2
  FROM path_counts pc
  CROSS JOIN totals t
)

/* 8.  Return the three pathways with the highest χ² values                */
SELECT
  pathway_id,
  a  AS targets_in_path,
  c  AS non_targets_in_path,
  b  AS targets_outside_path,
  d  AS non_targets_outside_path,
  chi2
FROM chi2_calc
ORDER BY chi2 DESC
LIMIT 3;