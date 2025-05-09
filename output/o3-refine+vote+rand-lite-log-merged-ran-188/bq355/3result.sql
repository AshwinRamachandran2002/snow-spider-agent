WITH quinapril_concept AS (
  -- RxNorm concept for Quinapril (RxCUI 35208)
  SELECT concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'RxNorm'
    AND concept_code = '35208'
),
related_concepts AS (
  -- Quinapril itself and any descendant concepts (e.g., dose forms, brand products, combos)
  SELECT descendant_concept_id AS concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor`
  WHERE ancestor_concept_id IN (SELECT concept_id FROM quinapril_concept)
  UNION DISTINCT
  SELECT concept_id FROM quinapril_concept
),
quinapril_users AS (
  -- Participants with at least one exposure to Quinapril or its related products
  SELECT DISTINCT person_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_exposure`
  WHERE drug_concept_id IN (SELECT concept_id FROM related_concepts)
),
population_counts AS (
  SELECT
    (SELECT COUNT(DISTINCT person_id) FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`)      AS total_participants,
    (SELECT COUNT(*)                  FROM quinapril_users)                                                     AS quinapril_users
)
SELECT
  ROUND(
    SAFE_DIVIDE(total_participants - quinapril_users, total_participants) * 100,
    4
  ) AS percent_not_using_quinapril
FROM population_counts;