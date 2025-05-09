-- Percentage of synthetic participants who did NOT use Quinapril (RxCUI 35208) or any related drug concepts
WITH ingredient AS (    -- standard concept_id for Quinapril
  SELECT concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'RxNorm'
    AND concept_code  = '35208'   -- Quinapril
    AND standard_concept = 'S'
  LIMIT 1
),
related_concepts AS (   -- all descendant drug concepts of Quinapril
  SELECT ca.descendant_concept_id AS concept_id
  FROM ingredient AS ing
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` AS ca
    ON ca.ancestor_concept_id = ing.concept_id
),
quinapril_users AS (    -- participants with any exposure to Quinapril or its descendants
  SELECT COUNT(DISTINCT person_id) AS user_cnt
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_exposure`
  WHERE drug_concept_id IN (SELECT concept_id FROM related_concepts)
),
all_participants AS (   -- total distinct participants
  SELECT COUNT(DISTINCT person_id) AS total_cnt
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`
)
SELECT
  ROUND(
    100.0 * (ap.total_cnt - qu.user_cnt) / ap.total_cnt, 2
  ) AS pct_participants_not_using_quinapril
FROM all_participants AS ap
CROSS JOIN quinapril_users AS qu;