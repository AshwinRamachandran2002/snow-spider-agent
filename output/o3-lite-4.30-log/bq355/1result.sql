WITH quinapril AS (
  SELECT concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'RxNorm' AND concept_code = '35208'
),
descendants AS (
  SELECT descendant_concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor`
  WHERE ancestor_concept_id = (SELECT concept_id FROM quinapril)
),
quinapril_users AS (
  SELECT DISTINCT person_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
  WHERE drug_concept_id IN (SELECT descendant_concept_id FROM descendants)
),
totals AS (
  SELECT
    (SELECT COUNT(*) FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`) AS total_participants,
    (SELECT COUNT(*) FROM quinapril_users) AS quinapril_users
)
SELECT
  ROUND(100.0 * (total_participants - quinapril_users) / total_participants, 4)
    AS percentage_not_using_quinapril
FROM totals;