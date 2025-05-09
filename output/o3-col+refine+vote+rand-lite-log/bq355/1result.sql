/* Percentage of participants NOT using Quinapril (RxCUI 35208) or any related formulation */
SELECT
  ROUND(
    100.0 * (tot.total_participants - q.quinapril_users) / tot.total_participants,
    4
  ) AS pct_not_using_quinapril
FROM (
  -- Total distinct participants represented in drug_era
  SELECT COUNT(DISTINCT person_id) AS total_participants
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
) tot
CROSS JOIN (
  -- Distinct participants exposed to any drug whose active ingredient is Quinapril
  SELECT COUNT(DISTINCT person_id) AS quinapril_users
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
  WHERE drug_concept_id IN (
    SELECT DISTINCT ds.drug_concept_id
    FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_strength` AS ds
    WHERE ds.ingredient_concept_id = (
      SELECT concept_id
      FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
      WHERE concept_code = '35208'                 -- RxCUI for Quinapril
      LIMIT 1
    )
  )
) q;