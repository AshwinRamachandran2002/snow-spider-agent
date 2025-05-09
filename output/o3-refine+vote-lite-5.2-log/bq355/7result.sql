WITH quinapril AS (
  -- RxNorm concept for Quinapril (RxCUI 35208)
  SELECT concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'RxNorm'
    AND concept_code  = '35208'
),
related_concepts AS (
  -- All descendant concepts (brands, combos, dose forms, etc.) plus Quinapril itself
  SELECT descendant_concept_id AS concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor`
  WHERE ancestor_concept_id = (SELECT concept_id FROM quinapril)
  UNION DISTINCT
  SELECT concept_id FROM quinapril
),
quinapril_users AS (
  -- People with any exposure to Quinapril or related medications
  SELECT DISTINCT person_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_exposure`
  WHERE drug_concept_id IN (SELECT concept_id FROM related_concepts)
),
population_counts AS (
  SELECT
    (SELECT COUNT(DISTINCT person_id) FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`)     AS total_persons,
    (SELECT COUNT(DISTINCT person_id) FROM quinapril_users)                                                    AS users
)
SELECT
  ROUND(100 * (total_persons - users) / total_persons, 4) AS percent_not_using_quinapril
FROM population_counts;