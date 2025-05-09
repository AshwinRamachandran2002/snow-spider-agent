/*  Fixed MOD type‑mismatch: convert FLOOR( … FLOAT64 … ) to INT64 before MOD   */
WITH valid_activities AS (
  SELECT
    a.activity_id,
    a.assay_id,
    a.standard_type,
    SAFE_CAST(a.standard_value AS FLOAT64)                    AS std_val,
    a.standard_relation                                       AS std_rel,
    SAFE_CAST(a.pchembl_value AS FLOAT64)                     AS pchembl,
    a.molregno,
    a.doc_id,
    SAFE_CAST(cp.heavy_atoms AS INT64)                        AS heavy_atoms,
    cs.canonical_smiles
  FROM  `bigquery-public-data.ebi_chembl.activities`          AS a
  JOIN  `bigquery-public-data.ebi_chembl.compound_properties` AS cp USING (molregno)
  JOIN  `bigquery-public-data.ebi_chembl.compound_structures` AS cs USING (molregno)
  WHERE
        SAFE_CAST(cp.heavy_atoms AS INT64) BETWEEN 10 AND 15
    AND a.standard_value IS NOT NULL
    AND SAFE_CAST(a.standard_value AS FLOAT64) IS NOT NULL
    AND SAFE_CAST(a.pchembl_value  AS FLOAT64)  > 10
),
/* counts per assay–molecule to filter sparse data & duplicates */
act_counts AS (
  SELECT
    assay_id, molregno,
    COUNT(*)                                                   AS act_cnt,
    SUM(CASE WHEN potential_duplicate='1' THEN 1 ELSE 0 END)  AS dup_cnt
  FROM `bigquery-public-data.ebi_chembl.activities`
  GROUP BY assay_id, molregno
),
filtered_acts AS (
  SELECT v.*
  FROM   valid_activities v
  JOIN   act_counts      c
    ON   c.assay_id = v.assay_id
   AND   c.molregno = v.molregno
  WHERE  c.act_cnt < 5
    AND  c.dup_cnt < 2
),
/* ---------- build synthetic publication dates ---------- */
docs_ranked AS (
  SELECT
    d.doc_id,
    COALESCE(CAST(d.year AS INT64), 1970)                       AS yr,
    IFNULL(d.journal,'UNKNOWN')                                 AS journal,
    SAFE_CAST(d.first_page AS INT64)                            AS first_page,
    ROW_NUMBER() OVER (PARTITION BY IFNULL(d.journal,'UNKNOWN'),
                                   COALESCE(CAST(d.year AS INT64),1970)
                       ORDER BY SAFE_CAST(d.first_page AS INT64))              AS rn,
    COUNT(*)   OVER (PARTITION BY IFNULL(d.journal,'UNKNOWN'),
                                 COALESCE(CAST(d.year AS INT64),1970))        AS tot
  FROM `bigquery-public-data.ebi_chembl.docs` d
),
datedocs AS (
  SELECT
    doc_id,
    -- percent rank (0‑1) but computed only once for reuse
    CASE
       WHEN tot = 1 THEN 0.0
       ELSE (CAST(rn-1 AS FLOAT64)/(tot-1))
    END                                                          AS pct,
    yr
  FROM docs_ranked
),
pub_dates AS (
  SELECT
    doc_id,
    DATE(
      yr,
      CAST(FLOOR(pct * 11) AS INT64) + 1,                         -- month 1‑12
      MOD(CAST(FLOOR(pct * 308) AS INT64), 28) + 1               -- day   1‑28
    ) AS pub_date
  FROM datedocs
),
acts AS (
  SELECT f.*, p.pub_date
  FROM   filtered_acts f
  LEFT JOIN pub_dates p USING (doc_id)
),
/* ---------- qualifying pairs ---------- */
pair_base AS (
  SELECT
    a.assay_id,
    a.standard_type,
    a.activity_id          AS act1,
    b.activity_id          AS act2,
    a.canonical_smiles     AS smi1,
    b.canonical_smiles     AS smi2,
    a.std_val              AS val1,
    b.std_val              AS val2,
    a.std_rel              AS rel1,
    b.std_rel              AS rel2,
    GREATEST(a.heavy_atoms , b.heavy_atoms)                      AS max_heavy_atoms,
    GREATEST(a.pub_date    , b.pub_date   )                      AS latest_pub_date,
    GREATEST(SAFE_CAST(a.doc_id AS INT64),
             SAFE_CAST(b.doc_id AS INT64))                       AS highest_doc_id
  FROM acts a
  JOIN acts b
    ON  a.assay_id      = b.assay_id
   AND  a.standard_type = b.standard_type
   AND  a.molregno      < b.molregno               -- ensure different molecules & unique pair
)
/* ---------- final output ---------- */
SELECT
  assay_id,
  standard_type,
  act1, act2,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(act1, act2)))) AS uuid_by_activity,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(smi1, smi2)))) AS uuid_by_smiles,
  max_heavy_atoms,
  latest_pub_date,
  highest_doc_id,
  CASE
       WHEN rel1='=' AND rel2='=' AND val1 = val2 THEN 'no-change'
       WHEN val1 <  val2                         THEN 'increase'
       WHEN val1 >  val2                         THEN 'decrease'
       ELSE 'no-change'
  END                                            AS change_classification
FROM pair_base
ORDER BY latest_pub_date DESC, highest_doc_id DESC
LIMIT 100;