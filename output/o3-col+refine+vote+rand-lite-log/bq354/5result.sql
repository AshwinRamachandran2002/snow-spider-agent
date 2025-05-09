WITH icd_families AS (
  -- 1.  All ICD-10-CM concepts that start with L70/L20/L40/L80
  SELECT
    c.concept_id,
    CASE
      WHEN c.concept_code LIKE 'L70%' THEN 'acne'
      WHEN c.concept_code LIKE 'L20%' THEN 'atopic_dermatitis'
      WHEN c.concept_code LIKE 'L40%' THEN 'psoriasis'
      WHEN c.concept_code LIKE 'L80%' THEN 'vitiligo'
    END AS disease_group
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept` c
  WHERE c.vocabulary_id = 'ICD10CM'
    AND (c.concept_code LIKE 'L70%' OR c.concept_code LIKE 'L20%' 
         OR c.concept_code LIKE 'L40%' OR c.concept_code LIKE 'L80%')
),
mapped_std AS (
  -- 2.  Map those ICD-10-CM concepts to STANDARD concepts (concept_id_2)
  SELECT
    i.disease_group,
    cr.concept_id_2 AS standard_concept_id
  FROM icd_families i
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` cr
    ON cr.concept_id_1 = i.concept_id
   AND cr.relationship_id = 'Maps to'
),
all_std_concepts AS (
  -- 3.  Add every descendant STANDARD concept of the mapped concepts
  SELECT DISTINCT disease_group, standard_concept_id AS concept_id
  FROM mapped_std
  
  UNION DISTINCT
  
  SELECT DISTINCT
    m.disease_group,
    ca.descendant_concept_id AS concept_id
  FROM mapped_std m
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
    ON ca.ancestor_concept_id = m.standard_concept_id
),
participant_counts AS (
  -- 4.  Count distinct persons per disease group
  SELECT
    s.disease_group,
    COUNT(DISTINCT co.person_id) AS participant_cnt
  FROM all_std_concepts s
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` co
    ON co.condition_concept_id = s.concept_id
  GROUP BY s.disease_group
),
total_participants AS (
  -- 5.  Denominator: total unique persons in condition_occurrence
  SELECT COUNT(DISTINCT person_id) AS total_cnt
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`
)
-- 6.  Final percentages
SELECT
  p.disease_group,
  p.participant_cnt,
  ROUND(100.0 * p.participant_cnt / t.total_cnt, 4) AS pct_of_participants
FROM participant_counts p
CROSS JOIN total_participants t
ORDER BY pct_of_participants DESC;