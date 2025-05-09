/* -------------------------------------------------------------
   Corrected version – fixes MOD() type-mismatch by casting the
   FLOAT result of FLOOR() to INT64 before applying MOD().
   ------------------------------------------------------------- */
WITH
/* ---- 1.  Build a synthetic publication date for every DOC_ID --- */
doc_rank AS (
  SELECT
    doc_id,
    COALESCE(CAST(year AS INT64), 1970)                     AS yr,
    journal,
    SAFE_CAST(first_page AS INT64)                          AS first_page_int,
    --
    PERCENT_RANK() OVER (
      PARTITION BY journal, COALESCE(CAST(year AS INT64), 1970)
      ORDER BY SAFE_CAST(first_page AS INT64)
    )                                                       AS pr
  FROM `bigquery-public-data.ebi_chembl.docs_30`
),
doc_calendar AS (
  SELECT
    doc_id,
    DATE(
      yr,
      1 + CAST(FLOOR(pr * 11) AS INT64),                    -- month 1-12
      1 + MOD(CAST(FLOOR(pr * 308) AS INT64), 28)           -- day   1-28
    )                                                       AS pub_date
  FROM doc_rank
),

/* ---- 2.  Activity rows after all row-level filters ------------- */
base AS (
  SELECT
    a.activity_id,
    a.assay_id,
    a.standard_type,
    a.standard_value,
    a.molregno,
    CAST(cp.heavy_atoms AS INT64)                           AS heavy_atoms,
    cs.canonical_smiles,
    a.doc_id,
    dc.pub_date
  FROM `bigquery-public-data.ebi_chembl.activities_30`          AS a
  JOIN `bigquery-public-data.ebi_chembl.compound_properties_29` AS cp
    ON a.molregno = CAST(cp.molregno AS INT64)
  JOIN `bigquery-public-data.ebi_chembl.compound_structures`    AS cs
    ON a.molregno = CAST(cs.molregno AS INT64)
  LEFT JOIN doc_calendar AS dc
    ON a.doc_id = dc.doc_id
  WHERE a.standard_value          IS NOT NULL
    AND a.pchembl_value           > 10
    AND a.potential_duplicate     < 2
    AND CAST(cp.heavy_atoms AS INT64) BETWEEN 10 AND 15
),

/* ---- 3.  Keep only assays having < 5 qualifying rows ----------- */
small_bucket AS (
  SELECT assay_id, standard_type
  FROM   base
  GROUP  BY assay_id, standard_type
  HAVING COUNT(*) < 5
),

filtered AS (
  SELECT b.*
  FROM   base AS b
  JOIN   small_bucket USING (assay_id, standard_type)
)

/* ---- 4.  Enumerate every unordered pair of different molecules - */
SELECT
  f1.activity_id                                                 AS activity_id_1,
  f2.activity_id                                                 AS activity_id_2,
  f1.assay_id,
  f1.standard_type,
  CASE
    WHEN f1.standard_value > f2.standard_value THEN 'decrease'
    WHEN f1.standard_value < f2.standard_value THEN 'increase'
    ELSE                                                        'no-change'
  END                                                            AS change_class,
  GREATEST(f1.heavy_atoms, f2.heavy_atoms)                       AS max_heavy_atoms,
  GREATEST(
    COALESCE(f1.pub_date, DATE '1970-01-01'),
    COALESCE(f2.pub_date, DATE '1970-01-01')
  )                                                             AS latest_pub_date,
  GREATEST(CAST(f1.doc_id AS INT64), CAST(f2.doc_id AS INT64))   AS max_doc_id,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(f1.activity_id AS A,
                                   f2.activity_id AS B))))       AS activity_pair_uuid,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(f1.canonical_smiles AS SMILES_A,
                                   f2.canonical_smiles AS SMILES_B)))) AS smiles_pair_uuid
FROM   filtered AS f1
JOIN   filtered AS f2
  ON   f1.assay_id      = f2.assay_id
 AND  f1.standard_type = f2.standard_type
 AND  f1.molregno     <> f2.molregno
 AND  f1.activity_id  <  f2.activity_id;