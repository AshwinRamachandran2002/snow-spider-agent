WITH total_participants AS (
  SELECT COUNT(DISTINCT person_id) AS total
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`
), condition_counts AS (
  SELECT
    CASE
      WHEN condition_source_value LIKE '7061%' THEN 'Acne'
      WHEN condition_source_value LIKE '6918%' THEN 'Atopic dermatitis'
      WHEN condition_source_value LIKE '6961%' THEN 'Psoriasis'
      WHEN condition_source_value LIKE '7090%' THEN 'Vitiligo'
    END AS Condition,
    COUNT(DISTINCT person_id) AS participant_count
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`
  WHERE condition_source_value LIKE '7061%'
     OR condition_source_value LIKE '6918%'
     OR condition_source_value LIKE '6961%'
     OR condition_source_value LIKE '7090%'
  GROUP BY Condition
)
SELECT
  Condition,
  ROUND((participant_count / total_participants.total) * 100, 4) AS Percentage_of_participants
FROM condition_counts, total_participants;