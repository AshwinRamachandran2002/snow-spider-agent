-- percentage of participants NOT using quinapril (RxCUI 35208) or any of its related formulations
WITH quinapril_ancestor AS (         -- RxNorm concept for quinapril
  SELECT concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'RxNorm'
    AND concept_code   = '35208'               -- RxCUI for quinapril
  LIMIT 1
),
quinapril_family AS (                -- all concepts that map to, or are descendants of, quinapril
  SELECT descendant_concept_id AS concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor`
  WHERE ancestor_concept_id = (SELECT concept_id FROM quinapril_ancestor)
),
users AS (                           -- participants ever exposed to any quinapril concept
  SELECT DISTINCT person_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
  WHERE drug_concept_id IN (SELECT concept_id FROM quinapril_family)
),
population AS (                      -- all synthetic participants
  SELECT DISTINCT person_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`
)
SELECT
  ROUND(
    (1 - SAFE_DIVIDE((SELECT COUNT(*) FROM users),
                     (SELECT COUNT(*) FROM population))) * 100,
    4
  ) AS percentage_not_using_quinapril
;