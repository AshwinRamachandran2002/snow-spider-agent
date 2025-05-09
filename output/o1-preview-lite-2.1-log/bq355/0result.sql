SELECT
  ROUND(100.0 * (1 - (quinapril_related_users / total_participants)), 4) AS percentage_not_using_quinapril_related
FROM (
  SELECT
    (SELECT COUNT(DISTINCT person_id)
     FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`) AS total_participants,
    (SELECT COUNT(DISTINCT de.person_id)
     FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_exposure` AS de
     JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept` AS c
       ON de.drug_concept_id = c.concept_id
     WHERE LOWER(c.concept_name) LIKE '%quinapril%' AND c.vocabulary_id = 'RxNorm') AS quinapril_related_users
);