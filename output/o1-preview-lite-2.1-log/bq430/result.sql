WITH
  filtered_activities AS (
    SELECT
      a.activity_id,
      a.molregno,
      a.assay_id,
      a.standard_type,
      a.standard_value,
      a.standard_relation,
      SAFE_CAST(a.pchembl_value AS FLOAT64) AS pchembl_value,
      SAFE_CAST(cp.heavy_atoms AS INT64) AS heavy_atoms,
      a.standard_units,
      a.doc_id
    FROM
      `bigquery-public-data.ebi_chembl.activities` AS a
    INNER JOIN
      `bigquery-public-data.ebi_chembl.compound_properties` AS cp
    ON a.molregno = cp.molregno
    WHERE
      SAFE_CAST(cp.heavy_atoms AS INT64) BETWEEN 10 AND 15
      AND SAFE_CAST(a.pchembl_value AS FLOAT64) > 10
      AND a.standard_value IS NOT NULL
      AND a.standard_relation IS NOT NULL
  ),
  assays_with_few_activities AS (
    SELECT
      assay_id,
      COUNT(DISTINCT activity_id) AS activity_count
    FROM
      filtered_activities
    GROUP BY
      assay_id
    HAVING
      activity_count < 5
  ),
  activities_no_duplicates AS (
    SELECT
      fa.*
    FROM
      filtered_activities AS fa
    LEFT JOIN (
      SELECT
        molregno,
        assay_id,
        standard_value,
        COUNT(*) AS duplicate_count
      FROM
        filtered_activities
      GROUP BY
        molregno, assay_id, standard_value
      HAVING
        COUNT(*) >= 2
    ) AS duplicates
    ON
      fa.molregno = duplicates.molregno
      AND fa.assay_id = duplicates.assay_id
      AND fa.standard_value = duplicates.standard_value
    WHERE
      duplicates.molregno IS NULL
  ),
  final_activities AS (
    SELECT
      fa.*
    FROM
      activities_no_duplicates AS fa
    WHERE
      fa.assay_id IN (SELECT assay_id FROM assays_with_few_activities)
  ),
  docs_with_pub_dates AS (
    SELECT
      doc_id,
      DATE(pub_year, month, day) AS publication_date
    FROM
      (
        SELECT
          doc_id,
          pub_year,
          percent_rank,
          -- Compute Month
          IFNULL(CAST(FLOOR(percent_rank * 11) + 1 AS INT64), 1) AS month,
          -- Compute Day
          IFNULL(
            CAST(MOD(CAST(FLOOR(percent_rank * 308) AS INT64), 28) + 1 AS INT64),
            1
          ) AS day
        FROM (
          SELECT
            d.doc_id,
            IFNULL(SAFE_CAST(d.year AS INT64), 1970) AS pub_year,
            SAFE_DIVIDE(
              SAFE_CAST(
                RANK() OVER(PARTITION BY d.journal, SAFE_CAST(d.year AS INT64) ORDER BY SAFE_CAST(d.first_page AS INT64)) - 1 AS FLOAT64
              ),
              NULLIF(COUNT(*) OVER(PARTITION BY d.journal, SAFE_CAST(d.year AS INT64)) -1, 0)
            ) AS percent_rank
          FROM
            `bigquery-public-data.ebi_chembl.docs` AS d
          WHERE
            d.doc_id IS NOT NULL
            AND SAFE_CAST(d.first_page AS INT64) IS NOT NULL
            AND d.journal IS NOT NULL
            AND d.year IS NOT NULL
        )
      )
  )
SELECT DISTINCT
  GREATEST(fa1.heavy_atoms, fa2.heavy_atoms) AS Max_heavy_atom_count,
  COALESCE(
    CAST(GREATEST(fa1_pub.publication_date, fa2_pub.publication_date) AS STRING),
    CAST(fa1_pub.publication_date AS STRING),
    CAST(fa2_pub.publication_date AS STRING),
    '1970-01-01') AS Latest_publication_date,
  GREATEST(SAFE_CAST(fa1.doc_id AS INT64), SAFE_CAST(fa2.doc_id AS INT64)) AS Highest_doc_id,
  CASE
    WHEN SAFE_CAST(fa1.standard_value AS FLOAT64) > SAFE_CAST(fa2.standard_value AS FLOAT64) THEN 'decrease'
    WHEN SAFE_CAST(fa1.standard_value AS FLOAT64) < SAFE_CAST(fa2.standard_value AS FLOAT64) THEN 'increase'
    ELSE 'no-change'
  END AS Change_classification,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(fa1.activity_id, fa2.activity_id, cs1.canonical_smiles, cs2.canonical_smiles)))) AS UUID
FROM
  final_activities AS fa1
JOIN
  final_activities AS fa2
  ON fa1.assay_id = fa2.assay_id
     AND fa1.standard_type = fa2.standard_type
     AND fa1.molregno < fa2.molregno
JOIN
  `bigquery-public-data.ebi_chembl.compound_structures` AS cs1
  ON fa1.molregno = cs1.molregno
JOIN
  `bigquery-public-data.ebi_chembl.compound_structures` AS cs2
  ON fa2.molregno = cs2.molregno
LEFT JOIN
  docs_with_pub_dates AS fa1_pub
  ON fa1.doc_id = fa1_pub.doc_id
LEFT JOIN
  docs_with_pub_dates AS fa2_pub
  ON fa2.doc_id = fa2_pub.doc_id
LIMIT 100;