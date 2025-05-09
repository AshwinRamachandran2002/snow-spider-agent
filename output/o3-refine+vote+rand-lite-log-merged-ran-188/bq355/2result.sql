WITH quinapril_ingredient AS (
  -- concept_id(s) that exactly match RxNorm code 35208 (Quinapril)
  SELECT concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'RxNorm'
    AND concept_code = '35208'
),
quinapril_related AS (
  -- include all descendant concepts (brand names, different forms, combos, etc.)
  SELECT DISTINCT descendant_concept_id AS concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
  JOIN quinapril_ingredient qi
    ON ca.ancestor_concept_id = qi.concept_id
  
  UNION DISTINCT
  
  -- also keep the ingredient itself
  SELECT concept_id
  FROM quinapril_ingredient
),
quinapril_users AS (
  -- people who have ever used Quinapril or related concepts
  SELECT DISTINCT person_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
  WHERE drug_concept_id IN (SELECT concept_id FROM quinapril_related)
),
totals AS (
  SELECT
    (SELECT COUNT(DISTINCT person_id) FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`) AS total_participants,
    (SELECT COUNT(DISTINCT person_id) FROM quinapril_users) AS quinapril_users
)
SELECT
  SAFE_DIVIDE((total_participants - quinapril_users) * 100.0, total_participants) AS percent_not_using_quinapril
FROM totals;