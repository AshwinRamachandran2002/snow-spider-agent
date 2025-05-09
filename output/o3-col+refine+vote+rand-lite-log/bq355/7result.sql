-- Percentage of participants NOT using Quinapril (RxCUI 35208) or any related drugs
WITH quinapril_ingredient AS (
  SELECT concept_id AS ingredient_concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE concept_code = '35208'          -- Quinapril RxCUI
  LIMIT 1
),
counts AS (
  SELECT
    -- Numerator: participants who used Quinapril or its descendants
    (SELECT COUNT(DISTINCT de.person_id)
       FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`           AS de
       JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor`   AS ca
         ON ca.descendant_concept_id = de.drug_concept_id
       CROSS JOIN quinapril_ingredient qi
      WHERE ca.ancestor_concept_id = qi.ingredient_concept_id) AS quinapril_users,

    -- Denominator: all participants with at least one drug_era record
    (SELECT COUNT(DISTINCT person_id)
       FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`) AS total_participants
)
SELECT
  ROUND((1 - SAFE_DIVIDE(quinapril_users, total_participants)) * 100, 4) AS pct_not_using_quinapril
FROM counts;