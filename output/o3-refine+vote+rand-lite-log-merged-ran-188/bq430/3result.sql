/*  -----------------------------------------------------------------------
    Pairs of different molecules (10-15 heavy atoms) measured in the same
    (assay_id , standard_type) that satisfy every quality filter described.

    Returned per pair:
      • UUIDs based on activity-ids and on canonical SMILES
      • change class of the standard_value (increase / decrease / no-change)
      • maximum heavy-atom count in the pair
      • latest synthetic publication date & highest doc_id
      • the common assay_id and standard_type
--------------------------------------------------------------------------- */
WITH
/* 1) Build synthetic publication dates for every document ---------------- */
doc_ranks AS (
  SELECT
    doc_id,
    COALESCE( SAFE_CAST(year AS INT64), 1970 )                       AS pub_year,
    PERCENT_RANK() OVER (PARTITION BY journal, year
                         ORDER BY SAFE_CAST(first_page AS INT64))    AS pr
  FROM `bigquery-public-data.ebi_chembl.docs_29`
),
doc_dates AS (
  SELECT
    doc_id,
    DATE(
      pub_year,
      1 + CAST(FLOOR(COALESCE(pr,0) * 11)  AS INT64),               -- month 1-12
      1 + CAST(MOD(CAST(FLOOR(COALESCE(pr,0) * 308) AS INT64),28)   -- day 1-28
                AS INT64)
    )                                                               AS pub_date
  FROM doc_ranks
),

/* 2) Activity rows that meet every atomic/quality filter --------------- */
qual_activities AS (
  SELECT
    a.activity_id,
    a.assay_id,
    a.molregno,
    a.standard_type,
    a.standard_relation,
    SAFE_CAST(a.standard_value AS FLOAT64)                 AS standard_value,
    SAFE_CAST(a.pchembl_value  AS FLOAT64)                 AS pchembl_val,
    SAFE_CAST(p.heavy_atoms    AS INT64)                   AS heavy_atoms,
    SAFE_CAST(a.potential_duplicate AS INT64)              AS dup_flag,
    s.canonical_smiles,
    ass.doc_id
  FROM `bigquery-public-data.ebi_chembl.activities_29`          AS a
  JOIN `bigquery-public-data.ebi_chembl.compound_properties_29` AS p
       ON a.molregno = p.molregno
  JOIN `bigquery-public-data.ebi_chembl.compound_structures_29` AS s
       ON a.molregno = s.molregno
  JOIN `bigquery-public-data.ebi_chembl.assays`                 AS ass
       ON a.assay_id = ass.assay_id
  WHERE SAFE_CAST(p.heavy_atoms AS INT64) BETWEEN 10 AND 15     -- 10-15 atoms
    AND SAFE_CAST(a.pchembl_value AS FLOAT64) > 10              -- pChEMBL > 10
    AND SAFE_CAST(a.standard_value AS FLOAT64) IS NOT NULL      -- numeric value
    AND SAFE_CAST(a.potential_duplicate AS INT64) < 2           -- <2 duplicates
),

/* 3) Keep only (assay_id , standard_type) that have <5 such activities -- */
act_counts AS (
  SELECT
    assay_id,
    standard_type,
    COUNT(DISTINCT activity_id) AS n_acts
  FROM qual_activities
  GROUP BY assay_id, standard_type
  HAVING n_acts < 5
),

filt AS (
  SELECT
    qa.*,
    dd.pub_date
  FROM qual_activities  AS qa
  JOIN act_counts       AS ac
    ON qa.assay_id      = ac.assay_id
   AND qa.standard_type = ac.standard_type
  LEFT JOIN doc_dates   AS dd
    ON qa.doc_id = dd.doc_id
),

/* 4) Produce ordered, non-self pairs inside every assay / std-type ----- */
pairs AS (
  SELECT
    f1.activity_id                               AS act_id_1,
    f2.activity_id                               AS act_id_2,
    f1.standard_value                            AS val1,
    f2.standard_value                            AS val2,
    f1.canonical_smiles                          AS smi1,
    f2.canonical_smiles                          AS smi2,
    GREATEST(f1.heavy_atoms , f2.heavy_atoms)    AS max_heavy_atoms,
    GREATEST( COALESCE(f1.pub_date , DATE '1970-01-01'),
              COALESCE(f2.pub_date , DATE '1970-01-01') )      AS latest_pub_date,
    GREATEST( SAFE_CAST(f1.doc_id AS INT64),
              SAFE_CAST(f2.doc_id AS INT64) )                  AS highest_doc_id,
    f1.assay_id,
    f1.standard_type
  FROM filt AS f1
  JOIN filt AS f2
    ON  f1.assay_id      = f2.assay_id
   AND f1.standard_type  = f2.standard_type
   AND f1.molregno      <> f2.molregno        -- different molecules
   AND f1.activity_id   <  f2.activity_id     -- ordered, avoid dup pairs
)

/* 5) Final projection with UUIDs & change classification --------------- */
SELECT
  act_id_1,
  act_id_2,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(act_id_1, act_id_2))))     AS uuid_by_act,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(smi1     , smi2))))        AS uuid_by_smiles,
  CASE
    WHEN val1 > val2 THEN 'decrease'
    WHEN val1 < val2 THEN 'increase'
    ELSE 'no-change'
  END                                                         AS change_class,
  max_heavy_atoms,
  FORMAT_DATE('%F', latest_pub_date)                          AS latest_pub_date,
  highest_doc_id,
  assay_id,
  standard_type
FROM pairs;