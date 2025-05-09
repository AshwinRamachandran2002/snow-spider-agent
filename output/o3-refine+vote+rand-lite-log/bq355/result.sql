WITH quinapril_ingredient AS (   -- Quinapril RxCUI = 35208
  SELECT concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'RxNorm'
    AND concept_code  = '35208'
),

related_concepts AS (           -- all descendants (forms/strengths/brands)
  SELECT descendant_concept_id AS concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor`
  WHERE ancestor_concept_id IN (SELECT concept_id FROM quinapril_ingredient)
),

quinapril_concept_set AS (
  SELECT concept_id FROM quinapril_ingredient
  UNION DISTINCT
  SELECT concept_id FROM related_concepts
),

users AS (                      -- participants ever exposed to quinapril‑related drugs
  SELECT DISTINCT person_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
  WHERE drug_concept_id IN (SELECT concept_id FROM quinapril_concept_set)
),

totals AS (                     -- total number of participants
  SELECT COUNT(DISTINCT person_id) AS total_persons
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`
),

user_counts AS (                -- number of quinapril users
  SELECT COUNT(DISTINCT person_id) AS user_cnt
  FROM users
)

SELECT
  ROUND((t.total_persons - u.user_cnt) / t.total_persons * 100, 4) AS percent_of_participants_not_using_quinapril
FROM totals t
CROSS JOIN user_counts u;