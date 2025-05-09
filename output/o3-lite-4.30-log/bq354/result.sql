WITH target_codes AS (
  SELECT 'L70' AS prefix, 'acne'               AS condition UNION ALL
  SELECT 'L20',            'atopic dermatitis' UNION ALL
  SELECT 'L40',            'psoriasis'         UNION ALL
  SELECT 'L80',            'vitiligo'
),
mapped_standard AS (
  SELECT DISTINCT
         tc.prefix,
         tc.condition,
         cr.concept_id_2 AS standard_concept_id
  FROM  target_codes tc
  JOIN  `bigquery-public-data.cms_synthetic_patient_data_omop.concept`            AS icd
        ON icd.vocabulary_id = 'ICD10CM'
       AND icd.concept_code  LIKE CONCAT(tc.prefix, '%')
  JOIN  `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` AS cr
        ON cr.concept_id_1   = icd.concept_id
       AND cr.relationship_id = 'Maps to'
),
descendants AS (
  SELECT DISTINCT
         ms.condition,
         ca.descendant_concept_id
  FROM  mapped_standard ms
  JOIN  `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
        ON ca.ancestor_concept_id = ms.standard_concept_id
),
condition_counts AS (
  SELECT
         d.condition,
         COUNT(DISTINCT co.person_id) AS patient_cnt
  FROM   descendants d
  JOIN   `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` co
         ON co.condition_concept_id = d.descendant_concept_id
  GROUP  BY d.condition
),
total_participants AS (
  SELECT COUNT(DISTINCT person_id) AS total_cnt
  FROM   `bigquery-public-data.cms_synthetic_patient_data_omop.person`
)
SELECT
       cc.condition,
       ROUND(100 * cc.patient_cnt / tp.total_cnt, 4) AS participant_percentage
FROM   condition_counts cc
CROSS  JOIN total_participants tp
ORDER  BY cc.condition;