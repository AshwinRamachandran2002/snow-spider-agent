/* ---------------------------------------------------------
   Build activity‑pairs that satisfy all conditions
----------------------------------------------------------*/
WITH docs_enriched AS (                       -- basic fields we need
  SELECT
    doc_id,
    COALESCE(journal,'Unknown')              AS journal,
    COALESCE(SAFE_CAST(year AS INT64),1970)  AS yr,
    SAFE_CAST(first_page AS INT64)           AS fp
  FROM `bigquery-public-data.ebi_chembl.docs`
),

docs_ranked AS (                             -- percent‑rank inside (journal,year)
  SELECT
    doc_id,
    yr,
    PERCENT_RANK() OVER (PARTITION BY journal,yr
                         ORDER BY fp)        AS pr
  FROM docs_enriched
),

pub_dates AS (                               -- synthetic publication DATE
  SELECT
    doc_id,
    DATE(
      yr,
      CAST(FLOOR(pr*11)  AS INT64) + 1,                                  -- month 1‑12
      MOD(CAST(FLOOR(pr*308) AS INT64),28) + 1                           -- day   1‑28
    ) AS pub_date
  FROM docs_ranked
),

/* ---------------------------------------------------------
   Filter activity rows
----------------------------------------------------------*/
filtered_act AS (
  SELECT
      a.activity_id,
      a.assay_id,
      a.standard_type,
      a.standard_relation                       AS rel,
      SAFE_CAST(a.standard_value AS FLOAT64)    AS val,
      SAFE_CAST(a.pchembl_value  AS FLOAT64)    AS pchem,
      a.molregno,
      a.potential_duplicate                     AS dup,
      a.doc_id,
      cp.heavy_atoms                            AS heavy_atoms,
      cs.canonical_smiles                       AS smi,
      d.pub_date
  FROM `bigquery-public-data.ebi_chembl.activities`          AS a
  JOIN `bigquery-public-data.ebi_chembl.compound_properties` AS cp USING (molregno)
  JOIN `bigquery-public-data.ebi_chembl.compound_structures` AS cs USING (molregno)
  JOIN pub_dates                                             AS d USING (doc_id)
  WHERE cp.heavy_atoms IS NOT NULL
    AND CAST(cp.heavy_atoms AS INT64) BETWEEN 10 AND 15      -- heavy‑atoms rule
    AND a.standard_value IS NOT NULL
    AND SAFE_CAST(a.pchembl_value AS FLOAT64) > 10           -- pChEMBL rule
),

/* ---------------------------------------------------------
   Count activities & duplicates per (mol, assay, std_type)
----------------------------------------------------------*/
mol_assay_stats AS (
  SELECT
    assay_id, standard_type, molregno,
    COUNT(*)                                   AS tot_act,
    SUM(CASE WHEN dup='1' THEN 1 ELSE 0 END)   AS dup_act
  FROM filtered_act
  GROUP BY assay_id, standard_type, molregno
),

valid_act AS (                                -- keep only those meeting the limits
  SELECT fa.*
  FROM filtered_act fa
  JOIN mol_assay_stats s
    ON s.assay_id      = fa.assay_id
   AND s.standard_type = fa.standard_type
   AND s.molregno      = fa.molregno
  WHERE s.tot_act < 5
    AND s.dup_act  < 2
),

/* ---------------------------------------------------------
   Build unordered molecule pairs within same assay & std_type
----------------------------------------------------------*/
pairs AS (
  SELECT
      a.activity_id AS act_id1,
      b.activity_id AS act_id2,
      a.smi         AS smi1,
      b.smi         AS smi2,
      a.val         AS val1,
      b.val         AS val2,
      a.rel         AS rel1,
      b.rel         AS rel2,
      GREATEST(CAST(a.heavy_atoms AS INT64),
               CAST(b.heavy_atoms AS INT64))        AS max_heavy_atoms,
      GREATEST(a.pub_date, b.pub_date)              AS latest_pub_date,
      GREATEST(CAST(a.doc_id AS INT64),
               CAST(b.doc_id AS INT64))             AS highest_doc_id,
      a.assay_id,
      a.standard_type
  FROM valid_act a
  JOIN valid_act b
    ON  a.assay_id      = b.assay_id
    AND a.standard_type = b.standard_type
    AND a.molregno     <> b.molregno
    AND a.molregno      <  b.molregno              -- prevent duplicate ordering
)

/* ---------------------------------------------------------
   Final projection with change classification & UUIDs
----------------------------------------------------------*/
SELECT
  assay_id,
  standard_type,
  act_id1,
  act_id2,
  max_heavy_atoms,
  latest_pub_date,
  highest_doc_id,
  CASE
      WHEN val1 > val2 THEN 'decrease'
      WHEN val1 < val2 THEN 'increase'
      ELSE                 'no-change'
  END                                               AS std_change_class,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(act_id1,act_id2)))) AS activity_pair_uuid,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(smi1   ,smi2 ))))   AS smiles_pair_uuid
FROM pairs;