/* ────────────────────────────────────────────────────────────────────────────────
   Top-3 lowest-level Homo sapiens Reactome pathways (TAS evidence only) that are
   most enriched for potent (≤100 nM) sorafenib targets – χ² test + contingency
   table counts (a,b,c,d).

   a = potent sorafenib targets      in pathway
   b = potent sorafenib targets      NOT in pathway
   c = other Reactome entities       in pathway
   d = other Reactome entities       NOT in pathway
   χ² is Pearson’s chi-squared statistic on the 2×2 table (a,b,c,d).
─────────────────────────────────────────────────────────────────────────────── */
WITH
/* 1.  Potent Homo-sapiens sorafenib targets  →  Reactome physical-entity IDs */
potent_targets AS (
  SELECT DISTINCT pe.stable_id                           -- Reactome PE ID
  FROM `isb-cgc-bq.reactome_versioned.physical_entity_v77` AS pe
  JOIN (
        SELECT DISTINCT i.target_uniprotID
        FROM   `isb-cgc-bq.targetome_versioned.interactions_v1` AS i
        JOIN   `isb-cgc-bq.targetome_versioned.experiments_v1`   AS e
               ON i.expID = e.expID
        WHERE  i.drugID IN (SELECT DISTINCT drugID
                            FROM `isb-cgc-bq.targetome_versioned.drug_synonyms_v1`
                            WHERE LOWER(synonym) LIKE '%sorafenib%')
          AND  i.targetSpecies = 'Homo sapiens'
          AND  e.exp_assayValueMedian <= 100
          AND (e.exp_assayValueLow  <= 100 OR e.exp_assayValueLow  IS NULL)
          AND (e.exp_assayValueHigh <= 100 OR e.exp_assayValueHigh IS NULL)
       ) AS s
       ON pe.uniprot_id = s.target_uniprotID
),
/* 2.  TAS-supported entity→pathway mappings */
tas_map AS (
  SELECT DISTINCT pe_stable_id, pathway_stable_id
  FROM `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77`
  WHERE evidence_code = 'TAS'
),
/* 3.  Eligible lowest-level Homo sapiens pathways */
eligible_paths AS (
  SELECT stable_id, name
  FROM   `isb-cgc-bq.reactome_versioned.pathway_v77`
  WHERE  lowest_level = TRUE
    AND  species      = 'Homo sapiens'
),
/* 4.  Universe of Reactome entities restricted to eligible pathways */
universe_entities AS (
  SELECT DISTINCT tm.pe_stable_id
  FROM   tas_map        AS tm
  JOIN   eligible_paths AS ep
         ON ep.stable_id = tm.pathway_stable_id
),
/* 5.  Per-pathway contingency-table counts (a and c) */
per_path_counts AS (
  SELECT
      ep.stable_id  AS pathway_id,
      ep.name       AS pathway_name,
      COUNT(DISTINCT IF(tm.pe_stable_id IN (SELECT * FROM potent_targets),
                        tm.pe_stable_id, NULL)) AS a,          -- targets  in pathway
      COUNT(DISTINCT IF(tm.pe_stable_id NOT IN (SELECT * FROM potent_targets),
                        tm.pe_stable_id, NULL)) AS c           -- non-targets in pathway
  FROM   eligible_paths AS ep
  JOIN   tas_map        AS tm
         ON tm.pathway_stable_id = ep.stable_id
  GROUP  BY pathway_id, pathway_name
),
/* 6.  Global totals for targets (T) and universe size (N) */
totals AS (
  SELECT
    (SELECT COUNT(*) FROM potent_targets      ) AS T,   -- total potent targets
    (SELECT COUNT(*) FROM universe_entities   ) AS N    -- total entities
),
/* 7.  χ² statistic for every pathway */
chi_square AS (
  SELECT
      pc.pathway_id,
      pc.pathway_name,
      pc.a,
      (tot.T - pc.a      )                     AS b,    -- targets     NOT in pathway
      pc.c,
      ((tot.N - tot.T) - pc.c)                 AS d,    -- non-targets NOT in pathway
      SAFE_DIVIDE(
        tot.N * POW(pc.a * ((tot.N - tot.T) - pc.c) -
                    ( (tot.T - pc.a) * pc.c ) , 2),
        (pc.a + (tot.T - pc.a)) *
        (pc.c + ((tot.N - tot.T) - pc.c)) *
        (pc.a + pc.c) *
        ((tot.T - pc.a) + ((tot.N - tot.T) - pc.c))
      )                                         AS chi_sq
  FROM per_path_counts AS pc
  CROSS JOIN totals  AS tot
)
/* 8.  Return the three pathways with highest χ² */
SELECT
  pathway_id                           AS pathway,
  pathway_name,
  a   AS targets_in_path,
  b   AS targets_not_in_path,
  c   AS nontargets_in_path,
  d   AS nontargets_not_in_path,
  chi_sq
FROM   chi_square
ORDER  BY chi_sq DESC
LIMIT 3;