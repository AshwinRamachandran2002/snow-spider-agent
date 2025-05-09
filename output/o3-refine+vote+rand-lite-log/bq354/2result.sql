-- % of participants that ever had Acne (L70), Atopic Dermatitis (L20),
-- Psoriasis (L40) or Vitiligo (L80) – including all ICD‑10‑CM
-- sub‑categories, mapped to STANDARD condition concepts and their
-- descendants

WITH root_icd AS (     -- 1. root ICD‑10‑CM concepts
  SELECT 'Acne'               AS disease , concept_id FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'ICD10CM' AND concept_code = 'L70'
  UNION ALL
  SELECT 'Atopic Dermatitis'  , concept_id FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'ICD10CM' AND concept_code = 'L20'
  UNION ALL
  SELECT 'Psoriasis'          , concept_id FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'ICD10CM' AND concept_code = 'L40'
  UNION ALL
  SELECT 'Vitiligo'           , concept_id FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'ICD10CM' AND concept_code = 'L80'
),

all_icd AS (           -- 2. add all ICD descendants (keeps root as well)
  SELECT r.disease, ca.descendant_concept_id AS icd_concept_id
  FROM root_icd r
  LEFT JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
    ON ca.ancestor_concept_id = r.concept_id
  UNION DISTINCT
  SELECT disease, concept_id AS icd_concept_id FROM root_icd
),

mapped_std AS (        -- 3. map every ICD concept to its STANDARD concept(s)
  SELECT DISTINCT
         ai.disease,
         cr.concept_id_2                 AS std_concept_id            -- standard (mostly SNOMED) concept
  FROM  all_icd ai
  JOIN  `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` cr
        ON cr.concept_id_1 = ai.icd_concept_id
       AND cr.relationship_id = 'Maps to'
),

all_std AS (           -- 4. add descendants of the mapped STANDARD concepts
  SELECT m.disease,
         COALESCE(ca.descendant_concept_id , m.std_concept_id) AS std_descendant_id
  FROM  mapped_std m
  LEFT JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
        ON ca.ancestor_concept_id = m.std_concept_id
  UNION DISTINCT
  SELECT disease, std_concept_id FROM mapped_std
),

persons_with_condition AS (    -- 5. persons that ever had any of those concepts
  SELECT DISTINCT
         s.disease,
         co.person_id
  FROM  all_std s
  JOIN  `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` co
        ON co.condition_concept_id = s.std_descendant_id
),

condition_counts AS (          -- 6. counts per disease
  SELECT disease,
         COUNT(DISTINCT person_id) AS person_cnt
  FROM   persons_with_condition
  GROUP  BY disease
),

total_persons AS (             -- 7. denominator
  SELECT COUNT(DISTINCT person_id) AS tot
  FROM   `bigquery-public-data.cms_synthetic_patient_data_omop.person`
)

-- 8. final result
SELECT
  cc.disease,
  cc.person_cnt                       AS participants,
  ROUND(100.0 * cc.person_cnt / tp.tot , 4) AS percent_of_participants
FROM   condition_counts cc
CROSS  JOIN total_persons tp
ORDER  BY cc.disease;