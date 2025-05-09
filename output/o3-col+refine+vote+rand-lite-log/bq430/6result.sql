/* -----------------------------------------------------------
   Corrected: cast FLOOR(...) to INT64 before using MOD()
   ----------------------------------------------------------- */
WITH base AS (   -- basic activity filter
  SELECT
    act.activity_id,
    act.assay_id,
    act.molregno,
    CAST(act.standard_value AS FLOAT64)          AS std_val,
    act.standard_relation,
    act.standard_type,
    CAST(cp.heavy_atoms AS INT64)                AS heavy_atoms,
    act.pchembl_value,
    act.potential_duplicate
  FROM `bigquery-public-data.ebi_chembl.activities_30`          act
  JOIN `bigquery-public-data.ebi_chembl.compound_properties_29` cp
    ON act.molregno = CAST(cp.molregno AS INT64)
  WHERE CAST(cp.heavy_atoms AS INT64) BETWEEN 10 AND 15
    AND act.standard_value IS NOT NULL
    AND act.pchembl_value  > 10
    AND act.potential_duplicate < 2
),
small_assays AS (
  SELECT assay_id, standard_type
  FROM base
  GROUP BY assay_id, standard_type
  HAVING COUNT(*) < 5
),
base2 AS (
  SELECT b.*
  FROM base b
  JOIN small_assays s
    ON b.assay_id      = s.assay_id
   AND b.standard_type = s.standard_type
),
/* ---------- add document information ---------------------- */
act_with_doc AS (
  SELECT
    b.*,
    SAFE_CAST(a.doc_id AS INT64) AS doc_id
  FROM base2 b
  LEFT JOIN `bigquery-public-data.ebi_chembl.activities` a
    ON SAFE_CAST(a.activity_id AS INT64) = b.activity_id
),
docs_rank AS (
  SELECT
    d.doc_id,
    d.journal,
    d.year,
    d.first_page,
    PERCENT_RANK() OVER (
      PARTITION BY d.journal, d.year
      ORDER BY SAFE_CAST(d.first_page AS INT64)
    ) AS pct_rank
  FROM `bigquery-public-data.ebi_chembl.docs_30` d
  WHERE d.year IS NOT NULL
),
doc_pub AS (
  SELECT
    dr.doc_id,
    DATE(
      COALESCE(dr.year, 1970),
      1 + CAST(FLOOR(COALESCE(dr.pct_rank,0)*11) AS INT64),                      -- month
      1 + MOD(CAST(FLOOR(COALESCE(dr.pct_rank,0)*308) AS INT64), 28)             -- day
    ) AS publication_date
  FROM docs_rank dr
),
base3 AS (
  SELECT
    awd.*,
    dp.publication_date,
    cs.canonical_smiles
  FROM act_with_doc awd
  LEFT JOIN doc_pub dp
    ON dp.doc_id = awd.doc_id
  LEFT JOIN `bigquery-public-data.ebi_chembl.compound_structures_29` cs
    ON CAST(cs.molregno AS INT64) = awd.molregno
  WHERE cs.canonical_smiles IS NOT NULL
),
/* ---------- build activity pairs -------------------------- */
pairs AS (
  SELECT
    b1.activity_id       AS act_id_1,
    b2.activity_id       AS act_id_2,
    b1.assay_id,
    b1.standard_type,
    b1.std_val           AS value_1,
    b2.std_val           AS value_2,
    b1.heavy_atoms       AS heavy_atoms_1,
    b2.heavy_atoms       AS heavy_atoms_2,
    b1.publication_date  AS pub_date_1,
    b2.publication_date  AS pub_date_2,
    b1.doc_id            AS doc_id_1,
    b2.doc_id            AS doc_id_2,
    b1.canonical_smiles  AS smiles_1,
    b2.canonical_smiles  AS smiles_2
  FROM base3 b1
  JOIN base3 b2
    ON b1.assay_id      = b2.assay_id
   AND b1.standard_type = b2.standard_type
   AND b1.activity_id  < b2.activity_id      -- avoid duplicates/self
   AND b1.molregno     <> b2.molregno
)
/* ---------- final output ---------------------------------- */
SELECT
  act_id_1,
  act_id_2,
  assay_id,
  standard_type,
  value_1,
  value_2,
  CASE
    WHEN value_1 < value_2 THEN 'increase'
    WHEN value_1 > value_2 THEN 'decrease'
    ELSE 'no-change'
  END                                       AS change_class,
  GREATEST(heavy_atoms_1, heavy_atoms_2)    AS max_heavy_atoms,
  GREATEST(pub_date_1, pub_date_2)          AS latest_publication_date,
  GREATEST(doc_id_1,   doc_id_2)            AS highest_doc_id,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(act_id_1, act_id_2))))     AS mmp_delta_uuid_act,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(smiles_1, smiles_2))))     AS mmp_delta_uuid_smiles
FROM pairs
LIMIT 100;