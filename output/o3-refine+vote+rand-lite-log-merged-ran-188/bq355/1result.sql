WITH base_concept AS (
  -- RxNorm concept for Quinapril (RxCUI 35208)
  SELECT concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'RxNorm'
    AND concept_code = '35208'
),
all_quinapril_concepts AS (
  -- include the ingredient itself and every descendant (form/strength, brand, etc.)
  SELECT concept_id
  FROM base_concept
  
  UNION DISTINCT
  
  SELECT descendant_concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor`
  WHERE ancestor_concept_id = (SELECT concept_id FROM base_concept)
),
quinapril_users AS (
  -- individuals exposed to Quinapril (any form) in their drug eras
  SELECT DISTINCT person_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
  WHERE drug_concept_id IN (SELECT concept_id FROM all_quinapril_concepts)
),
counts AS (
  SELECT
    (SELECT COUNT(DISTINCT person_id) FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`)   AS total_participants,
    (SELECT COUNT(DISTINCT person_id) FROM quinapril_users)                                                  AS quinapril_users
)
SELECT
  ROUND((total_participants - quinapril_users) / total_participants * 100, 4) AS pct_not_using_quinapril
FROM counts;