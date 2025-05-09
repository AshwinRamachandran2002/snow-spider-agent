/* --------------------------------------------------------------------------
   Pairs of different molecules measured in the same (assay_id, standard_type)
   under the following constraints
     • each molecule has 10–15 heavy atoms
     • both activities have pChEMBL > 10, standard_value not NULL,
       potential_duplicate < 2
     • fewer than 5 qualifying activities exist for that assay / type combo
   The query reports, for every unique ordered pair (low-, high-activity_id):
     – the maximum heavy–atom count in the pair
     – change_class  (increase / decrease / no-change)
     – latest synthetic publication date (see doc_dates CTE)
     – highest document id
     – UUIDs based on the two activity_ids (mmp_delta_uuid) and
       the two canonical SMILES (molpair_uuid)
---------------------------------------------------------------------------- */
WITH acts AS (                     -- basic activity filter
  SELECT
    activity_id,
    assay_id,
    molregno,
    standard_type,
    standard_value,
    standard_relation,
    pchembl_value,
    potential_duplicate,
    doc_id
  FROM `bigquery-public-data.ebi_chembl.activities_30`
  WHERE pchembl_value          > 10
    AND standard_value        IS NOT NULL
    AND potential_duplicate   < 2
),
acts_props AS (                    -- add heavy-atom count; keep 10-15 only
  SELECT
    a.*,
    CAST(cp.heavy_atoms AS INT64) AS heavy_atoms
  FROM acts AS a
  JOIN `bigquery-public-data.ebi_chembl.compound_properties_29` AS cp
    ON a.molregno = SAFE_CAST(cp.molregno AS INT64)
  WHERE CAST(cp.heavy_atoms AS INT64) BETWEEN 10 AND 15
),
good_assays AS (                   -- retain (assay_id, standard_type) with <5 acts
  SELECT assay_id, standard_type
  FROM   acts_props
  GROUP  BY assay_id, standard_type
  HAVING COUNT(*) < 5
),
good_acts AS (                     -- activities that pass every filter so far
  SELECT ap.*
  FROM   acts_props AS ap
  JOIN   good_assays AS ga USING (assay_id, standard_type)
),
pairs AS (                         -- generate DISTINCT unordered pairs
  SELECT DISTINCT
    LEAST(a1.activity_id, a2.activity_id)      AS activity_id_1,
    GREATEST(a1.activity_id, a2.activity_id)   AS activity_id_2,
    a1.assay_id,
    a1.standard_type,
    a1.standard_value  AS value1,
    a2.standard_value  AS value2,
    a1.standard_relation AS rel1,
    a2.standard_relation AS rel2,
    a1.heavy_atoms     AS ha1,
    a2.heavy_atoms     AS ha2,
    a1.doc_id          AS doc1,
    a2.doc_id          AS doc2,
    a1.molregno        AS mol1,
    a2.molregno        AS mol2
  FROM good_acts AS a1
  JOIN good_acts AS a2
    ON  a1.assay_id      = a2.assay_id
    AND a1.standard_type = a2.standard_type
    AND a1.molregno     <> a2.molregno
),
doc_dates AS (                     -- synthetic publication date per document
  SELECT
    doc_id,
    CONCAT(
      CAST(year AS STRING), '-',
      LPAD(CAST(1 + CAST(FLOOR(pr * 11) AS INT64) AS STRING), 2, '0'), '-',
      LPAD(CAST(1 + MOD(CAST(FLOOR(pr * 308) AS INT64), 28) AS STRING), 2, '0')
    ) AS pub_date
  FROM (
    SELECT
      doc_id,
      year,
      PERCENT_RANK() OVER (
        PARTITION BY journal, year
        ORDER BY SAFE_CAST(first_page AS INT64)
      ) AS pr
    FROM `bigquery-public-data.ebi_chembl.docs_30`
    WHERE year IS NOT NULL
  )
),
pairs_enriched AS (                -- add smiles & pub-dates
  SELECT
    p.*,
    cs1.canonical_smiles            AS smi1,
    cs2.canonical_smiles            AS smi2,
    d1.pub_date                     AS date1,
    d2.pub_date                     AS date2,
    GREATEST(p.ha1, p.ha2)          AS max_heavy_atoms,
    CASE
      WHEN SAFE_CAST(p.value1 AS FLOAT64) > SAFE_CAST(p.value2 AS FLOAT64)
           THEN 'decrease'
      WHEN SAFE_CAST(p.value1 AS FLOAT64) < SAFE_CAST(p.value2 AS FLOAT64)
           THEN 'increase'
      ELSE 'no-change'
    END                             AS change_class
  FROM pairs AS p
  JOIN `bigquery-public-data.ebi_chembl.compound_structures_29` AS cs1
       ON p.mol1 = SAFE_CAST(cs1.molregno AS INT64)
  JOIN `bigquery-public-data.ebi_chembl.compound_structures_29` AS cs2
       ON p.mol2 = SAFE_CAST(cs2.molregno AS INT64)
  LEFT JOIN doc_dates AS d1 ON p.doc1 = d1.doc_id
  LEFT JOIN doc_dates AS d2 ON p.doc2 = d2.doc_id
)
SELECT
  activity_id_1,
  activity_id_2,
  assay_id,
  standard_type,
  max_heavy_atoms,
  change_class,
  GREATEST(doc1, doc2)                                    AS max_doc_id,
  COALESCE(GREATEST(date1, date2), '1970-01-01')          AS latest_pub_date,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(activity_id_1,
                                   activity_id_2))))      AS mmp_delta_uuid,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(smi1, smi2))))         AS molpair_uuid
FROM pairs_enriched
ORDER BY activity_id_1, activity_id_2;