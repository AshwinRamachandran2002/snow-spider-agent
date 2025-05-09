WITH target_ingredient AS (
  -- RxNorm concept for Quinapril (RxCUI 35208)
  SELECT concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'RxNorm'
    AND concept_code   = '35208'          -- Quinapril RxCUI
  LIMIT 1
),
related_concepts AS (
  -- Quinapril and every concept that rolls up to it
  SELECT descendant_concept_id AS concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor`
  WHERE ancestor_concept_id = (SELECT concept_id FROM target_ingredient)
  UNION DISTINCT
  SELECT concept_id FROM target_ingredient
),
quinapril_users AS (
  -- Persons with any drug era containing Quinapril (or related) concepts
  SELECT DISTINCT person_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
  WHERE drug_concept_id IN (SELECT concept_id FROM related_concepts)
),
person_counts AS (
  SELECT
    (SELECT COUNT(DISTINCT person_id)
       FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`) AS total_persons,
    (SELECT COUNT(DISTINCT person_id) FROM quinapril_users)                AS quinapril_users
)
SELECT
  total_persons,
  quinapril_users,
  total_persons - quinapril_users                            AS persons_not_using_quinapril,
  ROUND( (total_persons - quinapril_users) / total_persons * 100, 4 )
                                                            AS percentage_not_using_quinapril
FROM person_counts;