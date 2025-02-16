-- Task: Find all pairs of distinct molecules tested in the same assay and with the same standard type, where each molecule in the pair meets the following criteria: has a heavy atom count between 10 and 15 (inclusive), has participated in fewer than 5 activities in that assay, has fewer than 2 duplicate activities in the assay, has a non-null standard value, and has a pChEMBL value greater than 10.
-- For each valid pair, report the maximum heavy atom count between the two molecules, the latest publication date calculated by ranking documents within the same journal and year based on their first page number and mapping this rank to synthetic month and day values, and the highest document ID between the two molecules.
-- Classify the change in standard values between the two molecules as 'increase', 'decrease', or 'no-change' based on the comparison of their standard values and standard relations using the following rules:
--   - 'decrease' if the first molecule's standard value is greater than the second's and neither molecule's standard relation is '<' or '<<' for the first, and '>' or '>>' for the second.
--   - 'increase' if the first molecule's standard value is less than the second's and neither molecule's standard relation is '>' or '>>' for the first, and '<' or '<<' for the second.
--   - 'no-change' if the standard values are equal and both standard relations are '=' or '~'.
-- Generate a UUID 'mmp_delta_uuid' by hashing the JSON stringified struct of both activity IDs, and generate a UUID 'mmp_search_uuid' by hashing the JSON stringified struct of both canonical SMILES and the integer 5.

SELECT 
  GREATEST(heavy_atoms_1, heavy_atoms_2) AS heavy_atoms_greatest,
  GREATEST(publication_date_1, publication_date_2) AS publication_date_greatest,
  GREATEST(doc_id_1, doc_id_2) AS doc_id_greatest,
  CASE 
    WHEN 
      standard_value_1 > standard_value_2 AND 
      standard_relation_1 NOT IN ('<', '<<') AND 
      standard_relation_2 NOT IN ('>', '>>')
    THEN 'decrease'
    WHEN
      standard_value_1 < standard_value_2 AND 
      standard_relation_1 NOT IN ('>', '>>') AND 
      standard_relation_2 NOT IN ('<', '<<') 
    THEN 'increase'
    WHEN
      standard_value_1 = standard_value_2 AND 
      standard_relation_1 IN ('=', '~') AND 
      standard_relation_2 IN ('=', '~') 
    THEN 'no-change'
    ELSE NULL
  END AS standard_change,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(activity_id_1, activity_id_2)))) AS mmp_delta_uuid,
  TO_HEX(MD5(TO_JSON_STRING(STRUCT(canonical_smiles_1, canonical_smiles_2, 5)))) AS mmp_search_uuid
FROM (
  SELECT 
    act.assay_id,
    act.standard_type,
    act.activity_id AS activity_id_1,
    CAST(act.standard_value AS NUMERIC) AS standard_value_1,
    act.standard_relation AS standard_relation_1,
    CAST(act.pchembl_value AS NUMERIC) AS pchembl_value_1,
    COUNT(*) OVER (PARTITION BY act.assay_id) AS count_activities_1,
    COUNT(*) OVER (PARTITION BY act.assay_id, act.molregno) AS duplicate_activities_1,
    act.molregno AS molregno_1,
    com.canonical_smiles AS canonical_smiles_1,
    CAST(cmp.heavy_atoms AS INT64) AS heavy_atoms_1,
    CAST(d.doc_id AS INT64) AS doc_id_1,
    DATE(
      COALESCE(CAST(d.year AS INT64), 1970), 
      COALESCE(CAST(FLOOR(PERCENT_RANK() OVER (
        PARTITION BY d.journal, d.year ORDER BY SAFE_CAST(d.first_page AS INT64)
      ) * 11) AS INT64) + 1, 1),
      COALESCE(MOD(CAST(FLOOR(PERCENT_RANK() OVER (
        PARTITION BY d.journal, d.year ORDER BY SAFE_CAST(d.first_page AS INT64)
      ) * 308) AS INT64), 28) + 1, 1)
    ) AS publication_date_1
  FROM `bigquery-public-data.ebi_chembl.activities_29` act
  JOIN `bigquery-public-data.ebi_chembl.compound_structures_29` com USING (molregno)
  JOIN `bigquery-public-data.ebi_chembl.compound_properties_29` cmp USING (molregno)
  LEFT JOIN `bigquery-public-data.ebi_chembl.docs_29` d USING (doc_id)
  WHERE standard_type IN (
    SELECT DISTINCT standard_type 
    FROM `bigquery-public-data.ebi_chembl.activities_29` 
    WHERE pchembl_value IS NOT NULL
  )
) a1
JOIN (
  SELECT 
    act.assay_id,
    act.standard_type,
    act.activity_id AS activity_id_2,
    CAST(act.standard_value AS NUMERIC) AS standard_value_2,
    act.standard_relation AS standard_relation_2,
    CAST(act.pchembl_value AS NUMERIC) AS pchembl_value_2,
    COUNT(*) OVER (PARTITION BY act.assay_id) AS count_activities_2,
    COUNT(*) OVER (PARTITION BY act.assay_id, act.molregno) AS duplicate_activities_2, 
    act.molregno AS molregno_2,
    com.canonical_smiles AS canonical_smiles_2, 
    CAST(cmp.heavy_atoms AS INT64) AS heavy_atoms_2,
    CAST(d.doc_id AS INT64) AS doc_id_2,
    DATE(
      COALESCE(CAST(d.year AS INT64), 1970), 
      COALESCE(CAST(FLOOR(PERCENT_RANK() OVER (
        PARTITION BY d.journal, d.year ORDER BY SAFE_CAST(d.first_page AS INT64)
      ) * 11) AS INT64) + 1, 1),
      COALESCE(MOD(CAST(FLOOR(PERCENT_RANK() OVER (
        PARTITION BY d.journal, d.year ORDER BY SAFE_CAST(d.first_page AS INT64)
      ) * 308) AS INT64), 28) + 1, 1)
    ) AS publication_date_2
  FROM `bigquery-public-data.ebi_chembl.activities_29` act
  JOIN `bigquery-public-data.ebi_chembl.compound_structures_29` com USING (molregno)
  JOIN `bigquery-public-data.ebi_chembl.compound_properties_29` cmp USING (molregno)
  LEFT JOIN `bigquery-public-data.ebi_chembl.docs_29` d USING (doc_id)
  WHERE standard_type IN (
    SELECT DISTINCT standard_type 
    FROM `bigquery-public-data.ebi_chembl.activities_29` 
    WHERE pchembl_value IS NOT NULL
  )
) a2 USING (assay_id, standard_type)
WHERE 
  a1.molregno_1 != a2.molregno_2 AND
  a1.count_activities_1 < 5 AND 
  a2.count_activities_2 < 5 AND 
  a1.heavy_atoms_1 BETWEEN 10 AND 15 AND
  a2.heavy_atoms_2 BETWEEN 10 AND 15 AND
  a1.standard_value_1 IS NOT NULL AND 
  a2.standard_value_2 IS NOT NULL AND
  a1.duplicate_activities_1 < 2 AND
  a2.duplicate_activities_2 < 2 AND
  a1.pchembl_value_1 > 10 AND
  a2.pchembl_value_2 > 10;