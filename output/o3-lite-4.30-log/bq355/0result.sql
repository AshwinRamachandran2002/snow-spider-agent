WITH quinapril AS (
  SELECT `concept_id`
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE `vocabulary_id` = 'RxNorm'
    AND `concept_code` = '35208'
),
quinapril_related AS (
  SELECT `descendant_concept_id`
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor`
  WHERE `ancestor_concept_id` IN (SELECT `concept_id` FROM quinapril)
),
quinapril_users AS (
  SELECT DISTINCT `person_id`
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
  WHERE `drug_concept_id` IN (SELECT `descendant_concept_id` FROM quinapril_related)
),
population AS (
  SELECT COUNT(DISTINCT `person_id`) AS total_persons
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`
)
SELECT
  ROUND(
    (1 - SAFE_DIVIDE(
          (SELECT COUNT(*) FROM quinapril_users),
          (SELECT total_persons FROM population)
        )) * 100,
    4
  ) AS percentage_not_using_quinapril;