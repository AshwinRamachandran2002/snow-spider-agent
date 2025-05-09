WITH families AS (
  SELECT 'L70' AS fam UNION ALL
  SELECT 'L20' UNION ALL
  SELECT 'L40' UNION ALL
  SELECT 'L80'
),
icd10_source AS (
  SELECT f.fam,
         c.concept_id
  FROM families f
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept` c
    ON c.vocabulary_id = 'ICD10CM'
   AND c.concept_code LIKE CONCAT(f.fam, '%')
),
mapped_std AS (
  SELECT DISTINCT
         s.fam,
         cr.concept_id_2 AS std_id
  FROM icd10_source s
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` cr
    ON cr.concept_id_1 = s.concept_id
   AND cr.relationship_id = 'Maps to'
  WHERE cr.concept_id_2 <> 0
),
hierarchy AS (
  SELECT m.fam, ca.descendant_concept_id AS concept_id
  FROM mapped_std m
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
    ON ca.ancestor_concept_id = m.std_id
  UNION DISTINCT
  SELECT fam, std_id
  FROM mapped_std
),
persons_per_family AS (
  SELECT DISTINCT h.fam, co.person_id
  FROM hierarchy h
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` co
    ON co.condition_concept_id = h.concept_id
),
family_counts AS (
  SELECT fam AS condition,
         COUNT(DISTINCT person_id) AS participants
  FROM persons_per_family
  GROUP BY fam
),
total AS (
  SELECT COUNT(DISTINCT person_id) AS total_participants
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`
)
SELECT
  fc.condition,
  ROUND(SAFE_DIVIDE(fc.participants, t.total_participants) * 100, 4) AS participant_percentage
FROM family_counts fc
CROSS JOIN total t
ORDER BY condition;