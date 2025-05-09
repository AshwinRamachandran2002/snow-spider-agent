WITH total_participants AS (
  SELECT COUNT(DISTINCT person_id) AS total_count
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`
),
quinapril_concept AS (
  SELECT concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'RxNorm' AND concept_code = '35208'
),
quinapril_descendants AS (
  SELECT descendant_concept_id AS concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor`
  WHERE ancestor_concept_id IN (SELECT concept_id FROM quinapril_concept)
),
quinapril_user_count AS (
  SELECT COUNT(DISTINCT person_id) AS quinapril_users
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_exposure`
  WHERE drug_concept_id IN (
    SELECT concept_id FROM quinapril_descendants
  )
)
SELECT
  ROUND(((total_count - quinapril_users) / total_count) * 100, 4) AS percentage_not_using_quinapril
FROM total_participants, quinapril_user_count;