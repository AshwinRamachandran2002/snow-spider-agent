/* ---------------------------------------------------------------------------
   Corrected query – fixes MOD() type-mismatch by casting FLOOR(...) to INT64
--------------------------------------------------------------------------- */
WITH
/* 1)  “small” assays (< 5 qualifying rows)                              */
small_assays AS (
  SELECT assay_id, standard_type
  FROM `bigquery-public-data.ebi_chembl.activities_30`
  WHERE standard_value IS NOT NULL
    AND pchembl_value  > 10
  GROUP BY assay_id, standard_type
  HAVING COUNT(*) < 5
),

/* 2)  qualifying activity rows                                          */
filtered AS (
  SELECT
    a.activity_id,
    a.assay_id,
    a.molregno,
    a.standard_relation,
    CAST(a.standard_value AS FLOAT64)            AS standard_value,
    a.standard_type,
    a.pchembl_value,
    CAST(a.doc_id AS STRING)                     AS doc_id,
    CAST(cp.heavy_atoms AS INT64)                AS heavy_atoms,
    cs.canonical_smiles
  FROM `bigquery-public-data.ebi_chembl.activities_30`          AS a
  JOIN small_assays USING (assay_id, standard_type)
  JOIN `bigquery-public-data.ebi_chembl.compound_properties_29` AS cp
        ON CAST(a.molregno AS STRING) = cp.molregno
  JOIN `bigquery-public-data.ebi_chembl.compound_structures_29` AS cs
        ON CAST(a.molregno AS STRING) = cs.molregno
  WHERE CAST(cp.heavy_atoms AS INT64) BETWEEN 10 AND 15
    AND a.pchembl_value  > 10
    AND a.standard_value IS NOT NULL
    AND (a.potential_duplicate IS NULL OR a.potential_duplicate < 2)
),

/* 3)  all ordered pairs of different molecules within same assay/type   */
pairs AS (
  SELECT
    f1.activity_id        AS activity_id_1,
    f1.assay_id,
    f1.standard_type,
    f1.standard_relation  AS relation_1,
    f1.standard_value     AS value_1,
    f1.heavy_atoms        AS heavy_1,
    f1.doc_id             AS doc_id_1,
    f1.canonical_smiles   AS smiles_1,

    f2.activity_id        AS activity_id_2,
    f2.standard_relation  AS relation_2,
    f2.standard_value     AS value_2,
    f2.heavy_atoms        AS heavy_2,
    f2.doc_id             AS doc_id_2,
    f2.canonical_smiles   AS smiles_2
  FROM filtered AS f1
  JOIN filtered AS f2
    ON  f1.assay_id      = f2.assay_id
    AND f1.standard_type = f2.standard_type
    AND f1.molregno      <> f2.molregno
    AND f1.activity_id   <  f2.activity_id
),

/* 4)  synthetic publication dates for every document                    */
docs_ranked AS (
  SELECT
    d.doc_id,
    d.journal,
    CAST(d.year AS INT64) AS yr,
    d.first_page,
    PERCENT_RANK() OVER (
      PARTITION BY d.journal, d.year
      ORDER BY SAFE_CAST(d.first_page AS INT64)
    )                     AS pct_rank
  FROM `bigquery-public-data.ebi_chembl.docs_29` AS d
),
docs_dates AS (
  SELECT
    doc_id,
    journal,
    yr AS year,
    first_page,
    DATE(
      COALESCE(yr, 1970),
      CAST(FLOOR(COALESCE(pct_rank,0)*11) AS INT64) + 1,
      MOD(CAST(FLOOR(COALESCE(pct_rank,0)*308) AS INT64), 28) + 1
    ) AS pub_date
  FROM docs_ranked
)

/* 5)  final projection                                                  */
SELECT
  p.activity_id_1,
  p.activity_id_2,
  p.assay_id,
  p.standard_type,

  GREATEST(p.heavy_1, p.heavy_2)                                  AS heavy_atoms_max,

  /* later synthetic publication date */
  CASE
    WHEN d1.pub_date IS NULL AND d2.pub_date IS NULL THEN DATE(1970,1,1)
    WHEN d1.pub_date IS NULL THEN d2.pub_date
    WHEN d2.pub_date IS NULL THEN d1.pub_date
    WHEN d1.pub_date >= d2.pub_date THEN d1.pub_date
    ELSE d2.pub_date
  END                                                             AS latest_pub_date,

  /* larger numeric doc_id (NULL → 0) */
  CAST(
    GREATEST(
      IFNULL(SAFE_CAST(p.doc_id_1 AS INT64), 0),
      IFNULL(SAFE_CAST(p.doc_id_2 AS INT64), 0)
    ) AS INT64
  )                                                               AS highest_doc_id,

  /* standard-value direction */
  CASE
    WHEN p.value_1 > p.value_2 THEN 'decrease'
    WHEN p.value_1 < p.value_2 THEN 'increase'
    ELSE                       'no-change'
  END                                                             AS change_classification,

  /* UUIDs */
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(p.activity_id_1, p.activity_id_2)))) AS uuid_activity_ids,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(p.smiles_1      , p.smiles_2))))      AS uuid_smiles
FROM pairs AS p
LEFT JOIN docs_dates AS d1 ON p.doc_id_1 = d1.doc_id
LEFT JOIN docs_dates AS d2 ON p.doc_id_2 = d2.doc_id
LIMIT 100;