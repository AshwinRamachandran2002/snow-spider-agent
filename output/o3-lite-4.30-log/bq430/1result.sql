WITH
/* -----------------------------------------------------------------
   1)  Synthetic publication date for every document
----------------------------------------------------------------- */
doc_dates AS (
  SELECT
    d.doc_id,
    COALESCE(CAST(d.year AS INT64), 1970)                                               AS pub_year,
    1 + CAST(FLOOR(
          COALESCE(
            PERCENT_RANK() OVER (PARTITION BY d.journal, COALESCE(d.year,'1970')
                                 ORDER BY SAFE_CAST(d.first_page AS INT64))
          ,0) * 11) AS INT64)                                                           AS pub_month,
    1 + MOD(CAST(FLOOR(
          COALESCE(
            PERCENT_RANK() OVER (PARTITION BY d.journal, COALESCE(d.year,'1970')
                                 ORDER BY SAFE_CAST(d.first_page AS INT64))
          ,0) * 308) AS INT64),28)                                                      AS pub_day
  FROM `bigquery-public-data.ebi_chembl.docs` d
),
doc_dates_with_date AS (
  SELECT
    doc_id,
    DATE(pub_year, pub_month, pub_day)  AS pub_date,
    pub_year,
    pub_month,
    pub_day
  FROM doc_dates
),

/* -----------------------------------------------------------------
   2)  Measurements that meet all single‑activity filters
----------------------------------------------------------------- */
filtered_activities AS (
  SELECT
    a.activity_id,
    a.assay_id,
    a.molregno,
    a.standard_type,
    a.standard_value,
    a.standard_relation,
    CAST(a.pchembl_value AS FLOAT64)                     AS pchembl_val,
    a.potential_duplicate,
    a.doc_id,
    CAST(cp.heavy_atoms AS INT64)                        AS heavy_atoms,
    cs.canonical_smiles
  FROM `bigquery-public-data.ebi_chembl.activities`          AS a
  JOIN `bigquery-public-data.ebi_chembl.compound_properties` AS cp
    ON cp.molregno = a.molregno
  JOIN `bigquery-public-data.ebi_chembl.compound_structures` AS cs
    ON cs.molregno = a.molregno
  WHERE cp.heavy_atoms IS NOT NULL
    AND CAST(cp.heavy_atoms AS INT64) BETWEEN 10 AND 15
    AND a.standard_value IS NOT NULL
    AND CAST(a.pchembl_value AS FLOAT64) > 10
),

/* -----------------------------------------------------------------
   3)  Retain (assay_id, molregno) combos with <5 rows and <2 duplicates
----------------------------------------------------------------- */
valid_rows AS (
  SELECT f.*
  FROM filtered_activities f
  JOIN (
        SELECT
          assay_id,
          molregno,
          COUNT(*)                                   AS act_cnt,
          COUNTIF(potential_duplicate = '1')         AS dup_cnt
        FROM filtered_activities
        GROUP BY assay_id, molregno
        HAVING act_cnt < 5 AND dup_cnt < 2
  ) ok
  USING (assay_id, molregno)
),

/* -----------------------------------------------------------------
   4)  Pair two different molecules in same assay & standard_type
----------------------------------------------------------------- */
paired AS (
  SELECT
    v1.activity_id                     AS activity_id_1,
    v2.activity_id                     AS activity_id_2,
    v1.standard_value                  AS value1,
    v2.standard_value                  AS value2,
    v1.standard_relation               AS rel1,
    v2.standard_relation               AS rel2,
    v1.canonical_smiles                AS smiles1,
    v2.canonical_smiles                AS smiles2,
    v1.doc_id                          AS doc_id_1,
    v2.doc_id                          AS doc_id_2,
    GREATEST(v1.heavy_atoms, v2.heavy_atoms)        AS max_heavy_atoms,
    CASE
      WHEN SAFE_CAST(v1.standard_value AS FLOAT64) < SAFE_CAST(v2.standard_value AS FLOAT64)
           AND v1.standard_relation IN ('=','<','<=')
           AND v2.standard_relation IN ('=','>','>=')
           THEN 'increase'
      WHEN SAFE_CAST(v1.standard_value AS FLOAT64) > SAFE_CAST(v2.standard_value AS FLOAT64)
           AND v1.standard_relation IN ('=','>','>=')
           AND v2.standard_relation IN ('=','<','<=')
           THEN 'decrease'
      WHEN SAFE_CAST(v1.standard_value AS FLOAT64) = SAFE_CAST(v2.standard_value AS FLOAT64)
           AND v1.standard_relation = '='
           AND v2.standard_relation = '='
           THEN 'no-change'
      ELSE NULL
    END                                            AS change_class
  FROM valid_rows v1
  JOIN valid_rows v2
    ON v1.assay_id      = v2.assay_id
   AND v1.standard_type = v2.standard_type
   AND v1.molregno     <> v2.molregno
   AND v1.activity_id  <  v2.activity_id          -- avoid mirrored duplicates
)

/* -----------------------------------------------------------------
   5)  Add publication dates, pick later date & highest doc_id, build UUIDs
----------------------------------------------------------------- */
SELECT
  p.max_heavy_atoms,
  FORMAT_DATE('%Y-%m-%d',
              CASE WHEN d1.pub_date >= d2.pub_date THEN d1.pub_date ELSE d2.pub_date END)
             AS latest_publication_date,
  CAST(GREATEST(SAFE_CAST(p.doc_id_1 AS INT64),
                SAFE_CAST(p.doc_id_2 AS INT64)) AS STRING)          AS highest_document_id,
  p.change_class                                                     AS standard_value_change,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(p.activity_id_1, p.smiles1))))    AS uuid_activity_smiles_1,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(p.activity_id_2, p.smiles2))))    AS uuid_activity_smiles_2
FROM paired p
JOIN doc_dates_with_date d1 ON d1.doc_id = p.doc_id_1
JOIN doc_dates_with_date d2 ON d2.doc_id = p.doc_id_2
WHERE p.change_class IS NOT NULL
LIMIT 100;