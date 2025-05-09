/* ------------------------------------------------------------
   Pairs of 10–15‑heavy‑atom molecules tested in the same assay
   & standard_type  (ChEMBL‑33, BigQuery public dataset)
-------------------------------------------------------------*/
WITH base AS (                       -- 1. raw activity/compound filter
  SELECT
    a.activity_id,
    a.assay_id,
    a.standard_type,
    CAST(a.standard_value AS FLOAT64)               AS standard_value,
    COALESCE(a.standard_relation,'=')               AS standard_relation,
    CAST(a.pchembl_value AS FLOAT64)                AS pchembl_value,
    a.molregno,
    a.doc_id,
    a.potential_duplicate,
    CAST(p.heavy_atoms AS INT64)                    AS heavy_atoms,
    s.canonical_smiles
  FROM `bigquery-public-data.ebi_chembl.activities`            a
  JOIN `bigquery-public-data.ebi_chembl.compound_properties`   p
       ON p.molregno = a.molregno
  JOIN `bigquery-public-data.ebi_chembl.compound_structures`   s
       ON s.molregno = a.molregno
  WHERE CAST(p.heavy_atoms AS INT64) BETWEEN 10 AND 15
    AND a.standard_value IS NOT NULL
    AND a.pchembl_value  IS NOT NULL
    AND CAST(a.pchembl_value AS FLOAT64) > 10
),
cnts AS (                         -- 2. enforce per‑assay rules & keep best pChEMBL
  SELECT
    b.*,
    COUNT(*) OVER (PARTITION BY molregno, assay_id)                                   AS tot_act_cnt,
    SUM(CASE WHEN potential_duplicate = '1' THEN 1 ELSE 0 END)
        OVER (PARTITION BY molregno, assay_id)                                        AS dup_cnt,
    ROW_NUMBER() OVER (PARTITION BY molregno, assay_id, standard_type
                       ORDER BY pchembl_value DESC, activity_id)                      AS rn_best
  FROM base b
),
filtered AS (
  SELECT *
  FROM cnts
  WHERE tot_act_cnt < 5
    AND dup_cnt     < 2
    AND rn_best      = 1
),
/* ---------- synthetic publication date per document ------------------ */
docs_ranked AS (
  SELECT
    d.doc_id,
    COALESCE(CAST(d.year AS INT64), 1970)                              AS yy,
    d.journal,
    SAFE_CAST(d.first_page AS INT64)                                   AS fp,
    PERCENT_RANK() OVER (
      PARTITION BY d.journal, COALESCE(CAST(d.year AS INT64), 1970)
      ORDER BY SAFE_CAST(d.first_page AS INT64)
    )                                                                  AS pctrank
  FROM `bigquery-public-data.ebi_chembl.docs` d
),
docs_date AS (
  SELECT
    doc_id,
    yy,
    CAST(IFNULL(FLOOR(pctrank*11)+1,1)                      AS INT64)  AS mm,
    CAST(IFNULL(MOD(CAST(FLOOR(pctrank*308) AS INT64),28)+1,1) AS INT64) AS dd
  FROM docs_ranked
),
act AS (                         -- 3. attach synthetic date
  SELECT
    f.*,
    DATE(d.yy, d.mm, d.dd) AS pub_date
  FROM filtered f
  LEFT JOIN docs_date d
    ON d.doc_id = f.doc_id
),
pairs AS (                       -- 4. ordered pairs of distinct molecules
  SELECT
    a.assay_id,
    a.standard_type,
    a.activity_id         AS act_id1,
    b.activity_id         AS act_id2,
    a.molregno            AS mol1,
    b.molregno            AS mol2,
    a.standard_value      AS val1,
    b.standard_value      AS val2,
    a.standard_relation   AS rel1,
    b.standard_relation   AS rel2,
    a.heavy_atoms         AS ha1,
    b.heavy_atoms         AS ha2,
    a.pub_date            AS date1,
    b.pub_date            AS date2,
    CAST(a.doc_id AS INT64) AS doc1,
    CAST(b.doc_id AS INT64) AS doc2,
    a.canonical_smiles    AS smi1,
    b.canonical_smiles    AS smi2
  FROM act a
  JOIN act b
    ON a.assay_id      = b.assay_id
   AND a.standard_type = b.standard_type
   AND a.molregno      < b.molregno
)
/* ---------- final result ------------------------------------------------------------- */
SELECT
  assay_id,
  standard_type,
  mol1                        AS molregno_1,
  mol2                        AS molregno_2,
  act_id1                     AS activity_id_1,
  act_id2                     AS activity_id_2,
  CASE
    WHEN ABS(val1 - val2) < 1e-9 THEN 'no-change'
    WHEN val1 > val2            THEN 'decrease'
    ELSE                              'increase'
  END                         AS change_class,
  GREATEST(ha1, ha2)          AS max_heavy_atoms,
  GREATEST(date1, date2)      AS latest_publication_date,
  CAST(GREATEST(doc1, doc2) AS STRING) AS highest_doc_id,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(LEAST(act_id1, act_id2),
                                   GREATEST(act_id1, act_id2)))))  AS uuid_from_act_ids,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(LEAST(smi1, smi2),
                                   GREATEST(smi1, smi2)))))        AS uuid_from_smiles
FROM pairs;