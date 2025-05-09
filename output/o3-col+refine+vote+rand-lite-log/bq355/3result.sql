WITH quinapril AS (
  -- RxNorm concept_id for Quinapril (code 35208)
  SELECT concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE concept_code = '35208'
),
quinapril_desc AS (
  -- All descendant drug concept_ids related to Quinapril
  SELECT descendant_concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor`
  WHERE ancestor_concept_id = (SELECT concept_id FROM quinapril)
),
quinapril_users AS (
  -- Unique participants with any Quinapril-related drug_era record
  SELECT COUNT(DISTINCT person_id) AS n_users
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
  WHERE drug_concept_id IN (SELECT descendant_concept_id FROM quinapril_desc)
),
total_people AS (
  -- Total unique participants represented in drug_era
  SELECT COUNT(DISTINCT person_id) AS n_total
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
)
-- Percentage of participants NOT using Quinapril or related medications
SELECT
  ROUND(100 * (1 - n_users / n_total), 4) AS pct_without_quinapril
FROM
  quinapril_users, total_people;