WITH quinapril_descendants AS (
  SELECT ca.descendant_concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept` c
    ON ca.ancestor_concept_id = c.concept_id
  WHERE c.concept_code = '35208'            -- RxCUI for quinapril
),
quinapril_users AS (
  SELECT COUNT(DISTINCT de.person_id) AS quinapril_users
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era` de
  JOIN quinapril_descendants qd
    ON de.drug_concept_id = qd.descendant_concept_id
),
population AS (
  SELECT COUNT(DISTINCT person_id) AS total_participants
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
)
SELECT
  population.total_participants - quinapril_users.quinapril_users AS participants_not_using_quinapril,
  population.total_participants,
  ROUND(
    100.0 * (population.total_participants - quinapril_users.quinapril_users) 
    / population.total_participants,
    4
  ) AS pct_not_using_quinapril
FROM quinapril_users, population;