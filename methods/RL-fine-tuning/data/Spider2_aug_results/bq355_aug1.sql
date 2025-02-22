-- Task: Please tell me the number of participants using quinapril and related medications (Quinapril RxCUI: 35208).
SELECT COUNT(DISTINCT de.person_id) AS quinapril_related_users
FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_exposure` AS de
JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept` AS c
  ON de.drug_concept_id = c.concept_id
WHERE LOWER(c.concept_name) LIKE '%quinapril%' AND c.vocabulary_id = 'RxNorm';