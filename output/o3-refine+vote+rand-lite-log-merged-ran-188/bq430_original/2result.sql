/* -----------------------------------------------------------
   Pairs of activities meeting the stated requirements
   ----------------------------------------------------------- */
WITH
/*------------- 1. add synthetic publication date to each document -------------*/
docs_enh AS (
  SELECT
    d.doc_id,
    COALESCE(CAST(d.year AS INT64), 1970)                       AS pub_year,
    d.journal,
    SAFE_CAST(d.first_page AS INT64)                            AS first_pg,
    ROW_NUMBER() OVER (PARTITION BY d.journal,
                                   COALESCE(CAST(d.year AS INT64),1970)
                       ORDER BY SAFE_CAST(d.first_page AS INT64))            AS rn,
    COUNT(*)    OVER (PARTITION BY d.journal,
                                   COALESCE(CAST(d.year AS INT64),1970))     AS tot
  FROM `bigquery-public-data.ebi_chembl.docs` d
),
docs_pct AS (
  SELECT
    doc_id,
    pub_year,
    IF(tot = 1, 0.0,
       (CAST(rn AS FLOAT64) - 1) / (CAST(tot AS FLOAT64) - 1))              AS pct
  FROM docs_enh
),
pub_dates AS (
  SELECT
    doc_id,
    CAST(FLOOR(pct * 11) + 1 AS INT64)                                       AS pub_month,
    CAST( MOD(CAST(FLOOR(pct * 308) AS INT64), 28) + 1 AS INT64)             AS pub_day,
    pub_year
  FROM docs_pct
),

/*------------- 2. activities with basic filters -------------------*/
good_act AS (
  SELECT
    a.activity_id,
    a.assay_id,
    a.standard_type,
    a.molregno,
    SAFE_CAST(a.standard_value AS FLOAT64)            AS sv_float,
    a.standard_relation,
    SAFE_CAST(a.pchembl_value AS FLOAT64)             AS pchembl,
    a.potential_duplicate,
    a.doc_id
  FROM `bigquery-public-data.ebi_chembl.activities`            AS a
  JOIN `bigquery-public-data.ebi_chembl.compound_properties`   AS p
       ON p.molregno = a.molregno
  WHERE
        SAFE_CAST(p.heavy_atoms AS INT64) BETWEEN 10 AND 15
    AND SAFE_CAST(a.standard_value AS FLOAT64) IS NOT NULL
    AND SAFE_CAST(a.pchembl_value  AS FLOAT64)  > 10
),

/*------------- 3. enforce per‑assay/per‑molecule occurrence rules -------------*/
good_act_filtered AS (
  SELECT ga.*
  FROM good_act ga
  JOIN (
        SELECT assay_id,
               molregno,
               COUNT(*)                                                  AS tot_act,
               SUM(CASE WHEN potential_duplicate='1' THEN 1 ELSE 0 END)  AS dup_cnt
        FROM good_act
        GROUP BY assay_id, molregno
       ) t
    ON  t.assay_id = ga.assay_id AND t.molregno = ga.molregno
  WHERE t.tot_act < 5
    AND t.dup_cnt < 2
),

/*------------- 4. add heavy atoms, SMILES and publication date -------------*/
act_enriched AS (
  SELECT
    g.*,
    SAFE_CAST(p.heavy_atoms AS INT64)                  AS heavy_atoms,
    s.canonical_smiles,
    pd.pub_year,
    pd.pub_month,
    pd.pub_day
  FROM good_act_filtered                     AS g
  JOIN `bigquery-public-data.ebi_chembl.compound_properties`    AS p
       ON p.molregno = g.molregno
  LEFT JOIN `bigquery-public-data.ebi_chembl.compound_structures` AS s
       ON s.molregno = g.molregno
  LEFT JOIN pub_dates pd
       ON pd.doc_id  = g.doc_id
),

/*------------- 5. build qualifying pairs taken from same assay & std‑type -----*/
pairs AS (
  SELECT
    a1.assay_id,
    a1.standard_type,
    a1.activity_id  AS act_id_1,
    a1.molregno     AS mol_1,
    a2.activity_id  AS act_id_2,
    a2.molregno     AS mol_2,
    a1.sv_float     AS sv1,
    a1.standard_relation AS rel1,
    a2.sv_float     AS sv2,
    a2.standard_relation AS rel2,
    GREATEST(a1.heavy_atoms, a2.heavy_atoms)                         AS max_heavy_atoms,
    (SELECT FORMAT('%04d-%02d-%02d', yy, mm, dd)
       FROM UNNEST([
              STRUCT(a1.pub_year AS yy, a1.pub_month AS mm, a1.pub_day AS dd),
              STRUCT(a2.pub_year,        a2.pub_month,      a2.pub_day)
            ])
       ORDER BY yy DESC, mm DESC, dd DESC LIMIT 1)                   AS latest_pub_date,
    GREATEST(SAFE_CAST(a1.doc_id AS INT64),
             SAFE_CAST(a2.doc_id AS INT64))                          AS highest_doc_id,
    a1.canonical_smiles                                              AS smi1,
    a2.canonical_smiles                                              AS smi2
  FROM act_enriched a1
  JOIN act_enriched a2
    ON  a1.assay_id      = a2.assay_id
    AND a1.standard_type = a2.standard_type
    AND a1.activity_id   < a2.activity_id    -- ensure unique unordered pair
    AND a1.molregno      <> a2.molregno
)

/*------------- 6. final projection with change class & UUIDs ------------------*/
SELECT
  assay_id,
  standard_type,
  act_id_1,
  mol_1,
  act_id_2,
  mol_2,
  max_heavy_atoms,
  latest_pub_date,
  highest_doc_id,
  CASE
    WHEN sv1 > sv2 THEN 'decrease'
    WHEN sv1 < sv2 THEN 'increase'
    ELSE               'no-change'
  END                                                     AS std_change,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(act_id_1, act_id_2)))) AS uuid_from_acts,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(smi1, smi2))))         AS uuid_from_smiles
FROM pairs;