-- % of participants with Acne (L70*), Atopic Dermatitis (L20*), Psoriasis (L40*), or Vitiligo (L80*)
-- based on ICD‑10‑CM codes mapped to their STANDARD descendants

WITH icd10_groups AS (       -- 1. four top‑level ICD‑10‑CM codes
  SELECT 'Acne'               AS disease, 'L70' AS icd10cm_code UNION ALL
  SELECT 'Atopic Dermatitis',        'L20' UNION ALL
  SELECT 'Psoriasis',                'L40' UNION ALL
  SELECT 'Vitiligo',                 'L80'
),

std_targets AS (             -- 2. map each ICD‑10‑CM code to standard concept(s)
  SELECT
    g.disease,
    cr.concept_id_2 AS std_concept_id
  FROM icd10_groups g
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept`              icd
          ON icd.vocabulary_id = 'ICD10CM'
         AND icd.concept_code  = g.icd10cm_code
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` cr
          ON cr.concept_id_1   = icd.concept_id
         AND cr.relationship_id = 'Maps to'
),

descendants AS (             -- 3. all standard descendants (plus the targets themselves)
  SELECT DISTINCT
    s.disease,
    ca.descendant_concept_id AS concept_id
  FROM std_targets s
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
        ON ca.ancestor_concept_id = s.std_concept_id
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept` c
        ON c.concept_id = ca.descendant_concept_id
       AND c.standard_concept = 'S'
  UNION DISTINCT
  SELECT
    s.disease,
    s.std_concept_id
  FROM std_targets s
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept` c
        ON c.concept_id = s.std_concept_id
       AND c.standard_concept = 'S'
),

persons_with_condition AS (  -- 4. persons having any of those concepts recorded
  SELECT DISTINCT
    d.disease,
    co.person_id
  FROM descendants d
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` co
       ON co.condition_concept_id = d.concept_id
),

disease_counts AS (          -- 5. # persons per disease
  SELECT
    disease,
    COUNT(DISTINCT person_id) AS persons_with_disease
  FROM persons_with_condition
  GROUP BY disease
),

total_persons AS (           -- 6. total # of participants
  SELECT COUNT(DISTINCT person_id) AS total_cnt
  FROM   `bigquery-public-data.cms_synthetic_patient_data_omop.person`
)

-- 7. final percentages
SELECT
  dc.disease,
  dc.persons_with_disease,
  tp.total_cnt                            AS total_participants,
  ROUND(dc.persons_with_disease / tp.total_cnt * 100, 4) AS percentage_of_participants
FROM disease_counts dc
CROSS JOIN total_persons tp
ORDER BY percentage_of_participants DESC;