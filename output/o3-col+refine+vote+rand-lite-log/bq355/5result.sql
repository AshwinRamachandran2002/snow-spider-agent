WITH quinapril_ancestor AS (
  -- Quinapril ingredient itself + any concept whose name contains 'quinapril'
  SELECT concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE concept_code = '35208'
     OR LOWER(concept_name) LIKE '%quinapril%'
),
quinapril_related AS (
  -- All descendant concepts (includes the ancestors themselves)
  SELECT DISTINCT ca.descendant_concept_id AS concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
  JOIN quinapril_ancestor qa
    ON ca.ancestor_concept_id = qa.concept_id
),
totals AS (
  SELECT
    COUNT(DISTINCT person_id) AS total_participants
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
),
users AS (
  SELECT
    COUNT(DISTINCT person_id) AS quinapril_users
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
  WHERE drug_concept_id IN (SELECT concept_id FROM quinapril_related)
)
SELECT
  ROUND(
    100.0 * (t.total_participants - u.quinapril_users) / t.total_participants,
    4
  ) AS pct_not_using_quinapril
FROM totals t
CROSS JOIN users u;