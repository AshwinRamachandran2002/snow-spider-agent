/* --------------------------------------------------------------
   Pairs of molecules (10–15 heavy atoms) tested in the same assay
   and standard‑type, meeting all stated conditions.
---------------------------------------------------------------*/
WITH
/* ---- 1.  Synthetic publication date for every document ---- */
docs_dates AS (
  SELECT
    d.doc_id,
    COALESCE(CAST(d.year AS INT64), 1970)                          AS pub_year,
    PERCENT_RANK() OVER (PARTITION BY d.journal, d.year
                         ORDER BY SAFE_CAST(d.first_page AS INT64)) AS pr
  FROM `bigquery-public-data.ebi_chembl.docs_33` d
),
docs_dates_final AS (
  SELECT
    doc_id,
    DATE(
      pub_year,
      CAST(FLOOR(pr*11) AS INT64) + 1,                             -- month 1‑12
      CAST(MOD(CAST(FLOOR(pr*308) AS INT64),28) AS INT64) + 1      -- day   1‑28
    ) AS synth_pub_date
  FROM docs_dates
),

/* ---- 2.  Activities that satisfy all filters --------------- */
valid_act AS (
  SELECT
    a.activity_id,
    a.assay_id,
    a.standard_type,
    CAST(a.standard_value AS FLOAT64)          AS std_val,
    a.molregno,
    a.doc_id,
    CAST(a.pchembl_value AS FLOAT64)           AS pchembl,
    CAST(SAFE_CAST(p.heavy_atoms AS INT64) AS INT64) AS heavy_atoms,
    s.canonical_smiles
  FROM `bigquery-public-data.ebi_chembl.activities_33`  a
  JOIN `bigquery-public-data.ebi_chembl.compound_properties_33` p USING (molregno)
  JOIN `bigquery-public-data.ebi_chembl.compound_structures_33`  s USING (molregno)
  WHERE
        SAFE_CAST(p.heavy_atoms AS INT64) BETWEEN 10 AND 15
    AND a.standard_value IS NOT NULL
    AND a.standard_relation = '='
    AND a.pchembl_value IS NOT NULL
    AND CAST(a.pchembl_value AS FLOAT64) > 10
    AND (a.potential_duplicate IS NULL OR a.potential_duplicate = '0')
),

/* ---- 3.  At most 4 activities per (assay,standard_type,mol) */
act_counts AS (
  SELECT
    v.*,
    COUNT(*) OVER (PARTITION BY assay_id, standard_type, molregno) AS n_act
  FROM valid_act v
),
act_filtered AS (
  SELECT AS VALUE
         ARRAY_AGG(a ORDER BY CAST(a.activity_id AS INT64) LIMIT 1)[OFFSET(0)]
  FROM act_counts a
  WHERE n_act < 5
  GROUP BY assay_id, standard_type, molregno
),

/* ---- 4.  Form unique unordered molecule pairs -------------- */
pairs AS (
  SELECT
    a.assay_id,
    a.standard_type,
    a.activity_id               AS act_id_a,
    b.activity_id               AS act_id_b,
    a.molregno                  AS mol_a,
    b.molregno                  AS mol_b,
    a.std_val                   AS std_val_a,
    b.std_val                   AS std_val_b,
    a.heavy_atoms               AS heavy_a,
    b.heavy_atoms               AS heavy_b,
    a.doc_id                    AS doc_a,
    b.doc_id                    AS doc_b,
    a.canonical_smiles          AS smi_a,
    b.canonical_smiles          AS smi_b
  FROM act_filtered a
  JOIN act_filtered b
    ON  a.assay_id      = b.assay_id
    AND a.standard_type = b.standard_type
    AND a.molregno      < b.molregno          -- avoid duplicates
)

/* ---- 5.  Final output -------------------------------------- */
SELECT
  assay_id,
  standard_type,
  mol_a,
  mol_b,
  GREATEST(heavy_a, heavy_b)                                   AS max_heavy_atoms,
  GREATEST(da.synth_pub_date, db.synth_pub_date)               AS latest_publication_date,
  GREATEST(CAST(doc_a AS INT64), CAST(doc_b AS INT64))         AS highest_doc_id,
  CASE
      WHEN std_val_a > std_val_b THEN 'decrease'
      WHEN std_val_a < std_val_b THEN 'increase'
      ELSE 'no-change'
  END                                                         AS standard_change,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(act_id_a, act_id_b))))      AS uuid_from_activities,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(smi_a, smi_b))))            AS uuid_from_smiles
FROM pairs
LEFT JOIN docs_dates_final da ON da.doc_id = pairs.doc_a
LEFT JOIN docs_dates_final db ON db.doc_id = pairs.doc_b
ORDER BY assay_id, mol_a, mol_b;