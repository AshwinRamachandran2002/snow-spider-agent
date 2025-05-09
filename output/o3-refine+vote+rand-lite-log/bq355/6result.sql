WITH quinapril_concepts AS (
  -- RxNorm concept for Quinapril (RxCUI 35208)
  SELECT concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'RxNorm'
    AND concept_code = '35208'
),
related_concepts AS (
  -- Quinapril and all its descendant concepts
  SELECT descendant_concept_id AS concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor`
  WHERE ancestor_concept_id IN (SELECT concept_id FROM quinapril_concepts)
  
  UNION DISTINCT
  
  SELECT concept_id
  FROM quinapril_concepts
),
quinapril_users AS (
  -- People who used Quinapril or a related medication
  SELECT DISTINCT person_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
  WHERE drug_concept_id IN (SELECT concept_id FROM related_concepts)
),
totals AS (
  SELECT
    (SELECT COUNT(*) FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`) AS total_participants,
    (SELECT COUNT(*) FROM quinapril_users)                                               AS users
)
SELECT
  ROUND( (total_participants - users) * 100.0 / total_participants , 4) AS percent_not_using_quinapril
FROM totals;