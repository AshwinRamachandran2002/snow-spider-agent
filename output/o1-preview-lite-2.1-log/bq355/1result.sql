SELECT
  ROUND(100.0 * (
    (SELECT COUNT(DISTINCT person_id) FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`) -
    (SELECT COUNT(DISTINCT de.person_id)
     FROM `bigquery-public-data.cms_synthetic_patient_data_omop.drug_exposure` de
     JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
       ON de.drug_concept_id = ca.descendant_concept_id
     WHERE ca.ancestor_concept_id = (
       SELECT concept_id
       FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
       WHERE concept_code = '35208' AND vocabulary_id = 'RxNorm')
    )
  ) /
  (SELECT COUNT(DISTINCT person_id) FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`),
  4) AS percentage_not_using_quinapril