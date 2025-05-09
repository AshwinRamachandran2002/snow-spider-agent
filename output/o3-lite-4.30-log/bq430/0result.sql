WITH docs_ranked AS (   -- rank docs inside (journal , year)
  SELECT
    d.doc_id,
    COALESCE(SAFE_CAST(d.year AS INT64), 1970)                             AS pub_year,
    d.journal,
    SAFE_CAST(d.first_page AS INT64)                                       AS first_page_int,
    RANK()  OVER (PARTITION BY d.journal,
                           COALESCE(SAFE_CAST(d.year AS INT64), 1970)
                  ORDER BY SAFE_CAST(d.first_page AS INT64))               AS rk,
    COUNT(*) OVER (PARTITION BY d.journal,
                            COALESCE(SAFE_CAST(d.year AS INT64), 1970))    AS tot
  FROM `bigquery-public-data.ebi_chembl.docs` d
),
docs_dates AS (          -- percent‑rank within (journal , year)
  SELECT
    doc_id,
    IFNULL(SAFE_DIVIDE(rk - 1, NULLIF(tot - 1, 0)), 0)                     AS pr,
    pub_year
  FROM docs_ranked
),
pub_dates AS (           -- synthetic month & day
  SELECT
    doc_id,
    1 + CAST(FLOOR(11  * pr) AS INT64)                                     AS month,
    1 + MOD(CAST(FLOOR(308 * pr) AS INT64), 28)                            AS day,
    pub_year
  FROM docs_dates
),
doc_final AS (           -- final publication date
  SELECT
    doc_id,
    DATE(pub_year, month, day)                                             AS publication_date
  FROM pub_dates
),
-------------------------------------------------------------------
-- Filter individual activity rows
-------------------------------------------------------------------
filtered_acts AS (
  SELECT
    a.activity_id,
    a.assay_id,
    a.molregno,
    a.standard_type,
    SAFE_CAST(a.standard_value AS FLOAT64)                 AS std_val,
    a.standard_relation,
    SAFE_CAST(a.pchembl_value  AS FLOAT64)                 AS pchembl,
    a.doc_id
  FROM `bigquery-public-data.ebi_chembl.activities` a
  JOIN `bigquery-public-data.ebi_chembl.compound_properties` p
    ON a.molregno = p.molregno
  WHERE SAFE_CAST(p.heavy_atoms AS INT64) BETWEEN 10 AND 15
    AND SAFE_CAST(a.pchembl_value AS FLOAT64) > 10
    AND a.standard_value IS NOT NULL
),
-------------------------------------------------------------------
-- Keep (molregno , assay_id) with activity‑count  < 5
-------------------------------------------------------------------
activity_counts AS (
  SELECT molregno, assay_id, COUNT(*) AS n_act
  FROM filtered_acts
  GROUP BY molregno, assay_id
  HAVING n_act < 5
),
-------------------------------------------------------------------
-- Keep (molregno , assay_id) with duplicate‑count < 2
-------------------------------------------------------------------
duplicate_counts AS (
  SELECT
    molregno,
    assay_id,
    SUM(CASE WHEN potential_duplicate = '1' THEN 1 ELSE 0 END) AS dup_cnt
  FROM `bigquery-public-data.ebi_chembl.activities`
  GROUP BY molregno, assay_id
  HAVING dup_cnt < 2
),
-------------------------------------------------------------------
-- Usable activity records after all molecule‑level constraints
-------------------------------------------------------------------
usable AS (
  SELECT fa.*
  FROM filtered_acts fa
  JOIN activity_counts  ac ON (fa.molregno, fa.assay_id) = (ac.molregno, ac.assay_id)
  JOIN duplicate_counts dc ON (fa.molregno, fa.assay_id) = (dc.molregno, dc.assay_id)
),
-------------------------------------------------------------------
-- Add heavy atom count, SMILES and publication date
-------------------------------------------------------------------
usable_plus AS (
  SELECT
    u.*,
    SAFE_CAST(cp.heavy_atoms AS INT64)                      AS heavy_atoms,
    cs.canonical_smiles,
    df.publication_date
  FROM usable u
  JOIN `bigquery-public-data.ebi_chembl.compound_properties`  cp ON u.molregno = cp.molregno
  JOIN `bigquery-public-data.ebi_chembl.compound_structures` cs ON u.molregno = cs.molregno
  LEFT JOIN doc_final df ON u.doc_id = df.doc_id
),
-------------------------------------------------------------------
-- Build molecule pairs inside same assay & standard_type
-------------------------------------------------------------------
pairs AS (
  SELECT
    a.activity_id                                          AS act_id_1,
    b.activity_id                                          AS act_id_2,
    a.std_val                                              AS val_1,
    b.std_val                                              AS val_2,
    GREATEST(a.heavy_atoms,        b.heavy_atoms)          AS max_heavy_atoms,
    GREATEST(a.publication_date,   b.publication_date)     AS latest_pub_date,
    GREATEST(SAFE_CAST(a.doc_id AS INT64),
             SAFE_CAST(b.doc_id AS INT64))                 AS highest_document_id,
    a.canonical_smiles                                     AS smiles_1,
    b.canonical_smiles                                     AS smiles_2
  FROM usable_plus a
  JOIN usable_plus b
    ON a.assay_id      = b.assay_id
   AND a.standard_type = b.standard_type
   AND a.molregno      <> b.molregno
   AND a.activity_id   <  b.activity_id    -- avoid mirrored duplicates
)
-------------------------------------------------------------------
SELECT
  max_heavy_atoms,
  FORMAT_DATE('%F', latest_pub_date)                         AS latest_publication_date,
  CAST(highest_document_id AS STRING)                        AS highest_document_id,
  CASE
    WHEN val_1 < val_2 THEN 'increase'
    WHEN val_1 > val_2 THEN 'decrease'
    ELSE 'no-change'
  END                                                        AS standard_value_change,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(act_id_1, act_id_2))))    AS uuid_activity_smiles_1,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(smiles_1, smiles_2))))    AS uuid_activity_smiles_2
FROM pairs
LIMIT 20;