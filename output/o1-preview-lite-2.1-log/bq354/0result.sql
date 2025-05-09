WITH total_participants AS (
  SELECT COUNT(DISTINCT person_id) AS total
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`
)
SELECT
  ROUND((COUNT(DISTINCT CASE WHEN condition_source_value IN ('7060', '7061') THEN person_id END) / MAX(total)) * 100, 4) AS acne_percentage,
  ROUND((COUNT(DISTINCT CASE WHEN condition_source_value IN ('6910', '6918') THEN person_id END) / MAX(total)) * 100, 4) AS atopic_dermatitis_percentage,
  ROUND((COUNT(DISTINCT CASE WHEN condition_source_value = '6961' THEN person_id END) / MAX(total)) * 100, 4) AS psoriasis_percentage,
  ROUND((COUNT(DISTINCT CASE WHEN condition_source_value = '70901' THEN person_id END) / MAX(total)) * 100, 4) AS vitiligo_percentage
FROM `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`, total_participants;