/*  Pairs of molecules fulfilling the requested criteria  */
WITH
/* ---------- synthetic publication date for every document ---------- */
doc_rank AS (
  SELECT
    d.doc_id,
    IFNULL(SAFE_CAST(d.year AS INT64), 1970)                        AS pub_year,
    d.journal,
    PERCENT_RANK() OVER (PARTITION BY d.journal, d.year
                         ORDER BY SAFE_CAST(d.first_page AS INT64)) AS pr
  FROM `bigquery-public-data.ebi_chembl.docs` AS d
),
doc_date AS (
  SELECT
    doc_id,
    pub_year                                   AS yy,
    -- month : floor(pr*11)+1  (1‑12)
    COALESCE(CAST(FLOOR(pr * 11) + 1 AS INT64), 1)                  AS mm,
    -- day   : floor(pr*308) mod 28 +1 (1‑28)
    COALESCE(
      CAST( MOD(CAST(FLOOR(pr * 308) AS INT64), 28) + 1 AS INT64 ),
      1)                                                            AS dd
  FROM doc_rank
),

/* ---------- eligible activity rows ---------- */
eligible AS (
  SELECT
    a.activity_id,
    a.assay_id,
    a.standard_type,
    SAFE_CAST(a.standard_value AS FLOAT64)                    AS std_val,
    SAFE_CAST(a.pchembl_value AS FLOAT64)                     AS pchembl,
    a.molregno,
    a.doc_id,
    SAFE_CAST(a.potential_duplicate AS INT64)                 AS dup_flag
  FROM `bigquery-public-data.ebi_chembl.activities` AS a
  WHERE a.standard_value           IS NOT NULL
    AND a.standard_relation        = '='
    AND a.pchembl_value            IS NOT NULL
    AND SAFE_CAST(a.pchembl_value AS FLOAT64)  > 10
    AND SAFE_CAST(a.potential_duplicate AS INT64) < 2
),

/* ---------- heavy‑atom filter (10‑15) ---------- */
eligible2 AS (
  SELECT
    e.*,
    SAFE_CAST(cp.heavy_atoms AS INT64) AS heavy_atoms
  FROM eligible AS e
  JOIN `bigquery-public-data.ebi_chembl.compound_properties` AS cp
    ON cp.molregno = e.molregno
  WHERE SAFE_CAST(cp.heavy_atoms AS INT64) BETWEEN 10 AND 15
),

/* ---------- molecules having <5 activities in the same assay ---------- */
kept AS (
  SELECT e2.*
  FROM eligible2 AS e2
  JOIN (
        SELECT assay_id, molregno, COUNT(*) AS c
        FROM eligible2
        GROUP BY assay_id, molregno
        HAVING c < 5
       ) AS ok
  ON  e2.assay_id = ok.assay_id
  AND e2.molregno = ok.molregno
),

/* ---------- add canonical SMILES ---------- */
final_act AS (
  SELECT
    k.*,
    cs.canonical_smiles
  FROM kept AS k
  JOIN `bigquery-public-data.ebi_chembl.compound_structures` AS cs
    ON cs.molregno = k.molregno
),

/* ---------- build all qualifying pairs within same assay & standard_type ---------- */
pairs AS (
  SELECT
    a.activity_id                     AS act_id_1,
    b.activity_id                     AS act_id_2,
    a.molregno                        AS mol_1,
    b.molregno                        AS mol_2,
    a.canonical_smiles                AS smi_1,
    b.canonical_smiles                AS smi_2,
    a.assay_id,
    a.standard_type,
    a.std_val                         AS val_1,
    b.std_val                         AS val_2,
    a.heavy_atoms                     AS heavy_1,
    b.heavy_atoms                     AS heavy_2,
    a.doc_id                          AS doc_1,
    b.doc_id                          AS doc_2,
    DATE(d1.yy, d1.mm, d1.dd)         AS date_1,
    DATE(d2.yy, d2.mm, d2.dd)         AS date_2
  FROM final_act AS a
  JOIN final_act AS b
    ON  a.assay_id      = b.assay_id
    AND a.standard_type = b.standard_type
    AND a.molregno     < b.molregno          -- distinct molecules, avoid duplicates
  JOIN doc_date AS d1 ON d1.doc_id = a.doc_id
  JOIN doc_date AS d2 ON d2.doc_id = b.doc_id
)

/* ---------- final output ---------- */
SELECT
  assay_id,
  standard_type,
  act_id_1,
  act_id_2,
  mol_1,
  mol_2,
  smi_1,
  smi_2,
  GREATEST(heavy_1, heavy_2)                                    AS max_heavy_atoms,
  CASE WHEN date_1 >= date_2 THEN date_1 ELSE date_2 END        AS latest_publication_date,
  GREATEST(SAFE_CAST(doc_1 AS INT64), SAFE_CAST(doc_2 AS INT64)) AS highest_doc_id,
  CASE
      WHEN val_1 = val_2 THEN 'no-change'
      WHEN val_1 < val_2 THEN 'increase'
      ELSE                  'decrease'
  END                                                           AS standard_value_change,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(act_id_1, act_id_2))))       AS uuid_from_activity_ids,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(smi_1, smi_2))))             AS uuid_from_smiles
FROM pairs;