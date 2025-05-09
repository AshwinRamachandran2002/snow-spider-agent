WITH total_persons AS (
  SELECT COUNT(DISTINCT person_id) AS total_cnt
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`
),
quinapril_related_concepts AS (
  -- all concepts representing Quinapril or its related drug forms
  SELECT descendant_concept_id AS drug_concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor`
  WHERE ancestor_concept_id = 35208   -- Quinapril (RxCUI 35208)
),
quinapril_users AS (
  SELECT DISTINCT de.person_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_exposure` AS de
  JOIN quinapril_related_concepts AS qc
    ON de.drug_concept_id = qc.drug_concept_id
),
summary AS (
  SELECT
    tp.total_cnt                                    AS total_participants,
    (SELECT COUNT(*) FROM quinapril_users)          AS users_cnt
  FROM total_persons tp
)
SELECT
  ROUND( (total_participants - users_cnt) * 100.0 / total_participants , 4)
    AS pct_participants_not_using_quinapril
FROM summary;