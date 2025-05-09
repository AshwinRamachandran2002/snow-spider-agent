WITH total AS (
  SELECT COUNT(DISTINCT person_id) AS total_participants
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
),
quinapril_users AS (
  SELECT COUNT(DISTINCT de.person_id) AS quinapril_users
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era` AS de
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` AS ca
    ON de.drug_concept_id = ca.descendant_concept_id
  WHERE ca.ancestor_concept_id = 1331235   -- Quinapril (RxCUI 35208)
)
SELECT
  ROUND((tot.total_participants - q.quinapril_users) / tot.total_participants * 100, 4) AS pct_not_using_quinapril
FROM total tot
CROSS JOIN quinapril_users q;