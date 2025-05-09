WITH ingredient AS (
  -- RxCUI 35208 corresponds to the Quinapril ingredient
  SELECT concept_id AS ingredient_concept_id
  FROM   `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE  concept_code = '35208'
),
quinapril_drug_concepts AS (
  -- All drug_concept_ids that contain the Quinapril ingredient
  SELECT DISTINCT drug_concept_id
  FROM   `bigquery-public-data.cms_synthetic_patient_data_omop.drug_strength`
  WHERE  ingredient_concept_id IN (SELECT ingredient_concept_id FROM ingredient)
),
quinapril_users AS (
  -- People exposed to any Quinapril‐related drug
  SELECT DISTINCT person_id
  FROM   `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
  WHERE  drug_concept_id IN (SELECT drug_concept_id FROM quinapril_drug_concepts)
),
all_users AS (
  -- Everyone who appears in Drug-Era
  SELECT DISTINCT person_id
  FROM   `bigquery-public-data.cms_synthetic_patient_data_omop.drug_era`
)
SELECT
  ROUND(
    (1 - SAFE_DIVIDE(
            (SELECT COUNT(*) FROM quinapril_users),
            (SELECT COUNT(*) FROM all_users)
          )
    ) * 100, 4
  ) AS pct_not_using_quinapril