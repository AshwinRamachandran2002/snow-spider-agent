SELECT
  condition,
  ROUND((participants_count / total_participants.total) * 100, 4) AS Percentage_of_participants
FROM (
  SELECT
    'Acne' AS condition,
    COUNT(DISTINCT person_id) AS participants_count
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`
  WHERE condition_source_value LIKE '706%'

  UNION ALL

  SELECT
    'Atopic dermatitis' AS condition,
    COUNT(DISTINCT person_id) AS participants_count
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`
  WHERE condition_source_value LIKE '691%'

  UNION ALL

  SELECT
    'Psoriasis' AS condition,
    COUNT(DISTINCT person_id) AS participants_count
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`
  WHERE condition_source_value LIKE '696%'

  UNION ALL

  SELECT
    'Vitiligo' AS condition,
    COUNT(DISTINCT person_id) AS participants_count
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`
  WHERE condition_source_value = '70901'
) AS condition_counts
CROSS JOIN (
  SELECT COUNT(DISTINCT person_id) AS total
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`
) AS total_participants
ORDER BY condition;