/* ---------------------------------------------------------------------------
   Final correction – MOD() now receives INT64 arguments
---------------------------------------------------------------------------- */

WITH docs_w_rank AS (      -- 1. rank & percent-rank inside journal/year
  SELECT
    SAFE_CAST(doc_id AS INT64)                       AS doc_id,
    COALESCE(SAFE_CAST(year AS INT64), 1970)         AS yr,
    journal,
    SAFE_CAST(first_page AS INT64)                   AS first_pg,
    PERCENT_RANK() OVER (
        PARTITION BY journal, SAFE_CAST(year AS INT64)
        ORDER BY SAFE_CAST(first_page AS INT64)
    )                                               AS pr
  FROM `bigquery-public-data.ebi_chembl.docs_29`
),

docs_dates AS (             -- 2. synthetic publication date (yr-mm-dd)
  SELECT
    doc_id,
    DATE(
      yr,
      1 + CAST(FLOOR(pr * 11) AS INT64),                           -- month
      1 + MOD(CAST(FLOOR(pr * 308) AS INT64), 28)                  -- day
    ) AS pub_date
  FROM docs_w_rank
),

filtered AS (               -- 3. activities meeting all row-level filters
  SELECT
    a.activity_id,
    a.assay_id,
    a.molregno,
    a.standard_relation,
    CAST(a.standard_value AS FLOAT64)           AS sv,
    a.standard_type,
    SAFE_CAST(cp.heavy_atoms AS INT64)          AS heavy_atoms,
    cs.canonical_smiles,
    SAFE_CAST(ass.doc_id AS INT64)              AS doc_id_int,
    dd.pub_date,
    a.pchembl_value
  FROM `bigquery-public-data.ebi_chembl.activities_30`          AS a
  JOIN `bigquery-public-data.ebi_chembl.compound_properties_29` AS cp
       ON CAST(a.molregno AS STRING) = cp.molregno
  JOIN `bigquery-public-data.ebi_chembl.compound_structures_29` AS cs
       ON CAST(a.molregno AS STRING) = cs.molregno
  JOIN `bigquery-public-data.ebi_chembl.assays`                 AS ass
       ON a.assay_id = CAST(ass.assay_id AS INT64)
  LEFT JOIN docs_dates             AS dd
       ON SAFE_CAST(ass.doc_id AS INT64) = dd.doc_id
  WHERE a.pchembl_value  > 10
    AND a.standard_value IS NOT NULL
    AND a.potential_duplicate < 2
    AND SAFE_CAST(cp.heavy_atoms AS INT64) BETWEEN 10 AND 15
),

small_sets AS (             -- 4. keep assay / standard_type with < 5 rows
  SELECT assay_id, standard_type
  FROM filtered
  GROUP BY assay_id, standard_type
  HAVING COUNT(*) < 5
),

qualified AS (              -- 5. final qualifying rows
  SELECT f.*
  FROM filtered AS f
  JOIN small_sets USING (assay_id, standard_type)
),

pairs AS (                  -- 6. unordered molecule pairs
  SELECT
    q1.activity_id                     AS activity_id_1,
    q2.activity_id                     AS activity_id_2,
    GREATEST(q1.heavy_atoms, q2.heavy_atoms)          AS max_heavy_atoms,
    CASE
      WHEN q1.standard_relation = '=' AND q2.standard_relation = '='
           AND q1.sv = q2.sv                          THEN 'no-change'
      WHEN q1.sv > q2.sv                              THEN 'decrease'
      WHEN q1.sv < q2.sv                              THEN 'increase'
      ELSE 'undetermined'
    END                                              AS change_class,
    CASE WHEN q1.pub_date >= q2.pub_date
         THEN q1.pub_date ELSE q2.pub_date END       AS latest_publication_date,
    GREATEST(q1.doc_id_int, q2.doc_id_int)           AS highest_doc_id,
    TO_HEX(MD5(TO_JSON_STRING(STRUCT(q1.activity_id,
                                     q2.activity_id))))          AS activity_pair_uuid,
    TO_HEX(MD5(TO_JSON_STRING(STRUCT(q1.canonical_smiles,
                                     q2.canonical_smiles))))     AS smiles_pair_uuid
  FROM qualified AS q1
  JOIN qualified AS q2
    ON q1.assay_id      = q2.assay_id
   AND q1.standard_type = q2.standard_type
   AND q1.molregno     <> q2.molregno
   AND q1.activity_id  <  q2.activity_id            -- avoid duplicates
)

-- 7. final output -----------------------------------------------------------
SELECT
  activity_id_1,
  activity_id_2,
  change_class,
  max_heavy_atoms,
  latest_publication_date,
  highest_doc_id,
  activity_pair_uuid,
  smiles_pair_uuid
FROM pairs;