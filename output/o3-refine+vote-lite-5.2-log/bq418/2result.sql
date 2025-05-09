WITH
/*-----------------------------------------------
-- 1.  Drug of interest : Sorafenib
------------------------------------------------*/
sorafenib_drugs AS (
  SELECT DISTINCT drugID
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1`
  WHERE LOWER(drugName) = 'sorafenib'
  UNION DISTINCT
  SELECT DISTINCT drugID
  FROM `isb-cgc-bq.targetome_versioned.drug_synonyms_v1`
  WHERE LOWER(synonym) LIKE '%sorafenib%'
),

/*-----------------------------------------------
-- 2.  Sorafenib → H. sapiens targets that pass the potency filter
------------------------------------------------*/
sorafenib_targets AS (
  SELECT DISTINCT i.target_uniprotID AS uniprot_id
  FROM `isb-cgc-bq.targetome_versioned.interactions_v1` i
  JOIN sorafenib_drugs               d  ON i.drugID = d.drugID
  JOIN `isb-cgc-bq.targetome_versioned.experiments_v1` e
        ON i.expID = e.expID
  WHERE i.targetSpecies = 'Homo sapiens'
        AND i.target_uniprotID IS NOT NULL
        AND e.exp_assayValueMedian <= 100
        AND (e.exp_assayValueLow  <= 100 OR e.exp_assayValueLow  IS NULL)
        AND (e.exp_assayValueHigh <= 100 OR e.exp_assayValueHigh IS NULL)
),

/*-----------------------------------------------
-- 3.  Universe of Reactome physical entities that
--     map (TAS evidence) to lowest‑level
--     Homo sapiens pathways
------------------------------------------------*/
universe AS (
  SELECT DISTINCT
         pe.uniprot_id,
         ptw.pathway_stable_id
  FROM `isb-cgc-bq.reactome_versioned.physical_entity_v77`      pe
  JOIN `isb-cgc-bq.reactome_versioned.pe_to_pathway_v77`        ptw
       ON pe.stable_id = ptw.pe_stable_id
  JOIN `isb-cgc-bq.reactome_versioned.pathway_v77`              pw
       ON ptw.pathway_stable_id = pw.stable_id
  WHERE ptw.evidence_code = 'TAS'
        AND pw.lowest_level = TRUE
        AND pw.species      = 'Homo sapiens'
        AND pe.uniprot_id IS NOT NULL
),

/*-----------------------------------------------
-- 4.  Flag each (pathway , UniProt) pair as
--     sorafenib target or not
------------------------------------------------*/
universe_flagged AS (
  SELECT
    u.pathway_stable_id AS pathway_id,
    u.uniprot_id,
    CASE WHEN t.uniprot_id IS NULL THEN 0 ELSE 1 END AS is_target
  FROM universe u
  LEFT JOIN sorafenib_targets t
         ON u.uniprot_id = t.uniprot_id
),

/*-----------------------------------------------
-- 5.  Counts inside each pathway
------------------------------------------------*/
pathway_in_counts AS (
  SELECT
    pathway_id,
    COUNT(DISTINCT CASE WHEN is_target = 1 THEN uniprot_id END) AS targets_in,
    COUNT(DISTINCT CASE WHEN is_target = 0 THEN uniprot_id END) AS non_targets_in
  FROM universe_flagged
  GROUP BY pathway_id
),

/*-----------------------------------------------
-- 6.  Totals across the whole universe
------------------------------------------------*/
totals AS (
  SELECT
    (SELECT COUNT(DISTINCT uniprot_id) FROM sorafenib_targets) AS total_targets,
    (SELECT COUNT(DISTINCT uniprot_id)
       FROM universe_flagged
       WHERE is_target = 0)                                    AS total_non_targets
),

/*-----------------------------------------------
-- 7.  Build 2×2 table for each pathway
------------------------------------------------*/
contingency AS (
  SELECT
    p.pathway_id,
    p.targets_in                                       AS a,
    t.total_targets     - p.targets_in                 AS b,
    p.non_targets_in                                   AS c,
    t.total_non_targets - p.non_targets_in             AS d
  FROM pathway_in_counts p
  CROSS JOIN totals t
),

/*-----------------------------------------------
-- 8.  Chi‑squared statistic
------------------------------------------------*/
chi_sq AS (
  SELECT
    pathway_id,
    a, b, c, d,
    (a + b + c + d)                                   AS n,
    ( (a*d - b*c)*(a*d - b*c) * (a + b + c + d) ) /
    NULLIF( (a + b)*(c + d)*(a + c)*(b + d) , 0)      AS chi_square
  FROM contingency
  WHERE (a + b)*(c + d)*(a + c)*(b + d) > 0           -- avoid divide‑by‑zero
)

/*-----------------------------------------------
-- 9.  Top 3 pathways with largest chi‑square
------------------------------------------------*/
SELECT
  chi.pathway_id                                              AS pathway_stable_id,
  pw.name                                                     AS pathway_name,
  chi.a                                                       AS targets_in_pathway,
  chi.b                                                       AS targets_outside_pathway,
  chi.c                                                       AS non_targets_in_pathway,
  chi.d                                                       AS non_targets_outside_pathway,
  chi.chi_square
FROM chi_sq chi
JOIN `isb-cgc-bq.reactome_versioned.pathway_v77` pw
  ON chi.pathway_id = pw.stable_id
ORDER BY chi.chi_square DESC
LIMIT 3;