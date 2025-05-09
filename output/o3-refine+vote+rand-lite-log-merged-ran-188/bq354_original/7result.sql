/*  Percentage of participants with acne (L70*), atopic dermatitis (L20*),
    psoriasis (L40*) and vitiligo (L80*), including all standard ICD‑10‑CM
    descendant concepts                                                  */

WITH
-- 1. Four root ICD‑10‑CM codes (standard concepts only)
target_ancestors AS (
  SELECT
    concept_id,
    concept_code
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'ICD10CM'
    AND concept_code IN ('L70','L20','L40','L80')
    AND standard_concept = 'S'
),

-- 2. Descendants (including the ancestors themselves)
descendants AS (
  SELECT
    ta.concept_code        AS group_code,
    ca.descendant_concept_id
  FROM target_ancestors ta
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
    ON ca.ancestor_concept_id = ta.concept_id
),

-- 3. Keep descendant concepts that are standard
valid_descendants AS (
  SELECT
    d.group_code,
    d.descendant_concept_id
  FROM descendants d
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept` c
    ON c.concept_id = d.descendant_concept_id
  WHERE c.standard_concept = 'S'
),

-- 4. People having at least one of those conditions
condition_persons AS (
  SELECT DISTINCT
    vd.group_code,
    co.person_id
  FROM valid_descendants vd
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` co
    ON co.condition_concept_id = vd.descendant_concept_id
),

-- 5. Count of participants per disease group
counts AS (
  SELECT
    group_code,
    COUNT(DISTINCT person_id) AS participant_count
  FROM condition_persons
  GROUP BY group_code
),

-- 6. Total participant count in the database
total AS (
  SELECT COUNT(DISTINCT person_id) AS total_participants
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`
),

-- 7. Ensure all four groups appear even if count is zero
all_groups AS (
  SELECT 'L70' AS group_code UNION ALL
  SELECT 'L20' UNION ALL
  SELECT 'L40' UNION ALL
  SELECT 'L80'
)

-- 8. Final result
SELECT
  CASE g.group_code
    WHEN 'L70' THEN 'Acne (L70*)'
    WHEN 'L20' THEN 'Atopic Dermatitis (L20*)'
    WHEN 'L40' THEN 'Psoriasis (L40*)'
    WHEN 'L80' THEN 'Vitiligo (L80*)'
  END                                   AS condition_group,
  COALESCE(c.participant_count, 0)      AS participant_count,
  t.total_participants,
  ROUND(
    COALESCE(c.participant_count, 0) * 100.0 / t.total_participants,
    4
  )                                     AS percentage_of_participants
FROM all_groups g
LEFT JOIN counts c
  ON c.group_code = g.group_code
CROSS JOIN total t
ORDER BY condition_group;