/* Pairs of compounds (10‑15 heavy atoms) tested in the same assay‑/
   standard‑type, meeting all constraints and with derived metadata  */

WITH clean_acts AS (         -- step‑1  filter individual activities
  SELECT
    a.activity_id,
    a.assay_id,
    a.standard_type,
    CAST(a.standard_value AS FLOAT64)          AS std_val,
    a.standard_relation                        AS std_rel,
    CAST(a.pchembl_value AS FLOAT64)           AS pchembl,
    a.molregno,                                -- STRING
    a.doc_id,
    cs.canonical_smiles                        AS smi,
    cp.heavy_atoms                             AS hatoms,
    a.potential_duplicate
  FROM `bigquery-public-data.ebi_chembl.activities`              AS a
  JOIN `bigquery-public-data.ebi_chembl.compound_properties_30`  AS cp
       ON CAST(cp.molregno AS STRING) = a.molregno               -- type‑safe join
  JOIN `bigquery-public-data.ebi_chembl.compound_structures`     AS cs
       ON cs.molregno = a.molregno
  WHERE
        cp.heavy_atoms BETWEEN 10 AND 15
    AND a.standard_value IS NOT NULL
    AND a.standard_relation = '='
    AND a.pchembl_value IS NOT NULL
    AND CAST(a.pchembl_value AS FLOAT64) > 10
),

good_acts AS (               -- step‑2  enforce ≤4 acts & <2 duplicates
  SELECT *
  FROM (
    SELECT
      ca.*,
      COUNT(*) OVER (PARTITION BY assay_id, molregno, standard_type)                         AS n_act,
      SUM(CASE WHEN potential_duplicate = '1' THEN 1 ELSE 0 END)
           OVER (PARTITION BY assay_id, molregno, standard_type)                             AS n_dup
    FROM clean_acts ca
  )
  WHERE n_act < 5
    AND n_dup < 2
),

docs_dates AS (              -- step‑3a base fields for synthetic dates
  SELECT
    doc_id,
    IFNULL(CAST(year AS INT64), 1970)                       AS yr,
    SAFE_CAST(first_page AS INT64)                          AS fp,
    journal
  FROM `bigquery-public-data.ebi_chembl.docs`
),

docs_ranked AS (             -- step‑3b percent‑rank within journal+year
  SELECT
    doc_id,
    yr,
    1 + CAST(FLOOR(PERCENT_RANK() OVER (PARTITION BY journal, yr
                                        ORDER BY IFNULL(fp, 0))) AS INT64)                  AS mn,
    1 + MOD(
            CAST(FLOOR(PERCENT_RANK() OVER (PARTITION BY journal, yr
                                            ORDER BY IFNULL(fp, 0)) * 308) AS INT64),
            28)                                                                             AS dy
  FROM docs_dates
),

doc_calendar AS (            -- step‑3c final synthetic publication date
  SELECT
    doc_id,
    DATE_FROM_UNIX_DATE(
      UNIX_DATE(DATE(yr, 1, 1)) + (mn - 1) * 28 + (dy - 1)
    ) AS pub_date
  FROM docs_ranked
),

acts_dated AS (              -- step‑4  attach publication dates
  SELECT
    g.*,
    dc.pub_date
  FROM good_acts g
  LEFT JOIN doc_calendar dc USING (doc_id)
),

pairs AS (                   -- step‑5  build unordered molecule pairs
  SELECT
    a1.activity_id                              AS act_id_1,
    a2.activity_id                              AS act_id_2,
    a1.molregno                                 AS mol_1,
    a2.molregno                                 AS mol_2,
    a1.smi                                      AS smi_1,
    a2.smi                                      AS smi_2,
    a1.std_val                                  AS val_1,
    a2.std_val                                  AS val_2,
    a1.hatoms                                   AS hatom_1,
    a2.hatoms                                   AS hatom_2,
    GREATEST(a1.hatoms, a2.hatoms)              AS max_hatoms,
    GREATEST(a1.doc_id, a2.doc_id)              AS highest_doc_id,
    GREATEST(a1.pub_date, a2.pub_date)          AS latest_pub,
    a1.assay_id,
    a1.standard_type
  FROM acts_dated a1
  JOIN acts_dated a2
    ON  a1.assay_id      = a2.assay_id
    AND a1.standard_type = a2.standard_type
    AND a1.molregno      < a2.molregno          -- avoid self & duplicate orientation
)

SELECT                         -- step‑6  final select & enrichment
  assay_id,
  standard_type,
  act_id_1,
  act_id_2,
  mol_1,
  mol_2,
  max_hatoms                                     AS max_heavy_atoms,
  latest_pub                                     AS latest_publication_date,
  highest_doc_id,
  CASE
      WHEN val_2 > val_1 THEN 'increase'
      WHEN val_2 < val_1 THEN 'decrease'
      ELSE 'no-change'
  END                                            AS change_class,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(act_id_1, act_id_2))))   AS uuid_from_acts,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(smi_1, smi_2))))         AS uuid_from_smiles
FROM pairs;