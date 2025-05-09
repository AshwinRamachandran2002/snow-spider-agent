WITH root_codes AS (
  SELECT 'L20' AS root_code UNION ALL
  SELECT 'L40' UNION ALL
  SELECT 'L70' UNION ALL
  SELECT 'L80'
),

-- every ICD‑10‑CM concept whose code begins with one of the 4 roots
icd_concepts AS (
  SELECT
    rc.root_code,
    c.concept_id AS src_concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept` AS c
  JOIN root_codes AS rc
       ON c.vocabulary_id = 'ICD10CM'
      AND c.concept_code LIKE CONCAT(rc.root_code, '%')
),

-- map those ICD‑10‑CM concepts to their STANDARD concepts
standard_maps AS (
  SELECT DISTINCT
    ic.root_code,
    cr.concept_id_2 AS std_concept_id
  FROM icd_concepts AS ic
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` AS cr
       ON cr.concept_id_1 = ic.src_concept_id
      AND cr.relationship_id = 'Maps to'
),

-- all participants who have at least one of the mapped standard concepts
condition_persons AS (
  SELECT
    sm.root_code,
    co.person_id
  FROM standard_maps AS sm
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` AS co
       ON co.condition_concept_id = sm.std_concept_id
),

per_root AS (
  SELECT
    rc.root_code,
    COUNT(DISTINCT cp.person_id) AS n_participants
  FROM root_codes AS rc
  LEFT JOIN condition_persons AS cp
         ON rc.root_code = cp.root_code
  GROUP BY rc.root_code
),

total AS (
  SELECT COUNT(DISTINCT person_id) AS total_participants
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`
)

SELECT
  pr.root_code AS condition,
  ROUND(100 * pr.n_participants / t.total_participants, 4) AS participant_percentage
FROM per_root AS pr
CROSS JOIN total AS t
ORDER BY pr.root_code;