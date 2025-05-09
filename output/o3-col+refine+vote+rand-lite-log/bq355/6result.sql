-- percentage of participants NOT using Quinapril (RxCUI 35208) or any descendant drug concept
WITH quinapril_descendants AS (
  SELECT DISTINCT ca.descendant_concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
  JOIN (
        SELECT concept_id
        FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
        WHERE concept_code = '35208'                  -- Quinapril RxCUI
           OR LOWER(concept_name) LIKE '%quinapril%'  -- safety-net text search
       ) q
    ON ca.ancestor_concept_id = q.concept_id
),
total_participants AS (
  SELECT COUNT(DISTINCT person_id) AS n_total
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
),
quinapril_users AS (
  SELECT COUNT(DISTINCT person_id) AS n_users
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
  WHERE drug_concept_id IN (SELECT descendant_concept_id FROM quinapril_descendants)
)
SELECT
  (t.n_total - u.n_users)                                         AS n_not_using_quinapril ,
  t.n_total                                                       AS n_total_participants ,
  100.0 * (t.n_total - u.n_users) / t.n_total AS pct_not_using_quinapril
FROM total_participants t
CROSS JOIN quinapril_users u;