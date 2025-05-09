WITH heavy_compounds AS (      -- 1️⃣ 10–15 heavy atoms
  SELECT
    molregno,
    SAFE_CAST(heavy_atoms AS INT64) AS heavy_atoms
  FROM `bigquery-public-data.ebi_chembl.compound_properties`
  WHERE SAFE_CAST(heavy_atoms AS INT64) BETWEEN 10 AND 15
),
mol_assay_good AS (            -- 2️⃣ <5 activities & <2 duplicates in assay
  SELECT molregno, assay_id
  FROM `bigquery-public-data.ebi_chembl.activities`
  GROUP BY molregno, assay_id
  HAVING COUNT(*) < 5
     AND COUNTIF(potential_duplicate = '1') < 2
),
activities_filtered AS (       -- 3️⃣ activity‑level filters
  SELECT
    a.activity_id,
    a.assay_id,
    a.molregno,
    SAFE_CAST(a.standard_value AS FLOAT64)  AS standard_value,
    a.standard_type,
    SAFE_CAST(a.pchembl_value  AS FLOAT64)  AS pchembl_value,
    SAFE_CAST(a.doc_id         AS INT64)    AS doc_id,
    hc.heavy_atoms
  FROM `bigquery-public-data.ebi_chembl.activities` a
  JOIN heavy_compounds hc       USING (molregno)
  JOIN mol_assay_good mg
    ON mg.molregno = a.molregno AND mg.assay_id = a.assay_id
  WHERE a.standard_value IS NOT NULL
    AND SAFE_CAST(a.pchembl_value AS FLOAT64) > 10
),
docs_calendar AS (             -- 4️⃣ synthetic publication date
  SELECT
    SAFE_CAST(doc_id AS INT64)                                   AS doc_id,
    COALESCE(SAFE_CAST(year AS INT64), 1970)                     AS yr,
    1 + CAST(FLOOR(pr * 11) AS INT64)                            AS month,
    1 + MOD(CAST(FLOOR(pr * 308) AS INT64), 28)                  AS day
  FROM (
    SELECT
      d.doc_id,
      d.year,
      d.journal,
      d.first_page,
      PERCENT_RANK() OVER (PARTITION BY d.journal, d.year
                           ORDER BY SAFE_CAST(d.first_page AS INT64)) AS pr
    FROM `bigquery-public-data.ebi_chembl.docs` d
  )
),
paired AS (                    -- 5️⃣ ordered activity pairs (same assay & type)
  SELECT
    A.activity_id  AS activity_id_a,
    B.activity_id  AS activity_id_b,
    GREATEST(A.heavy_atoms, B.heavy_atoms)   AS max_heavy_atoms,
    GREATEST(A.doc_id,      B.doc_id)        AS highest_document_id,
    CASE
      WHEN A.standard_value < B.standard_value THEN 'increase'
      WHEN A.standard_value > B.standard_value THEN 'decrease'
      ELSE 'no-change'
    END                                         AS standard_value_change,
    A.molregno AS molregno_a,
    B.molregno AS molregno_b
  FROM activities_filtered A
  JOIN activities_filtered B
    ON A.assay_id      = B.assay_id
   AND A.standard_type = B.standard_type
   AND A.molregno      <> B.molregno
   AND A.activity_id   <  B.activity_id
),
paired_with_smiles AS (        -- 6️⃣ add canonical SMILES
  SELECT
    p.*,
    s1.canonical_smiles AS smiles_a,
    s2.canonical_smiles AS smiles_b
  FROM paired p
  JOIN `bigquery-public-data.ebi_chembl.compound_structures` s1
    ON s1.molregno = p.molregno_a
  JOIN `bigquery-public-data.ebi_chembl.compound_structures` s2
    ON s2.molregno = p.molregno_b
),
final AS (                     -- 7️⃣ publication date + UUIDs
  SELECT
    pws.max_heavy_atoms,
    CONCAT(
      CAST(COALESCE(dc.yr,   1970) AS STRING),'-',
      LPAD(CAST(COALESCE(dc.month,1) AS STRING),2,'0'),'-',
      LPAD(CAST(COALESCE(dc.day,  1) AS STRING),2,'0')
    )                                           AS latest_publication_date,
    CAST(pws.highest_document_id AS STRING)    AS highest_document_id,
    pws.standard_value_change,
    TO_HEX(MD5(TO_JSON_STRING(STRUCT(pws.activity_id_a,
                                     pws.activity_id_b))))  AS uuid_activity_smiles_1,
    TO_HEX(MD5(TO_JSON_STRING(STRUCT(pws.smiles_a,
                                     pws.smiles_b))))       AS uuid_activity_smiles_2
  FROM paired_with_smiles pws
  LEFT JOIN docs_calendar dc
    ON dc.doc_id = pws.highest_document_id
)
SELECT                                  -- 8️⃣ requested output
  max_heavy_atoms,
  latest_publication_date,
  highest_document_id,
  standard_value_change,
  uuid_activity_smiles_1,
  uuid_activity_smiles_2
FROM final;