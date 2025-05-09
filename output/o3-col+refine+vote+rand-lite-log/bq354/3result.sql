/*  Percentage of participants with Acne (L70*), Atopic dermatitis (L20*),
    Psoriasis (L40*) and Vitiligo (L80*) based on STANDARD Condition concepts
    that are mapped from, or descended from, the ICD-10-CM families L70, L20,
    L40 and L80 (all sub-codes included)                                          */

WITH disease_roots AS (          -- 1) ICD-10-CM root prefixes of interest
  SELECT 'Acne (L70*)'               AS disease, 'L70' AS root_code UNION ALL
  SELECT 'Atopic dermatitis (L20*)', 'L20' UNION ALL
  SELECT 'Psoriasis (L40*)',         'L40' UNION ALL
  SELECT 'Vitiligo (L80*)',          'L80'
),

icd_family AS (                   -- 2) Every ICD-10-CM concept whose code starts with the root prefix
  SELECT dr.disease,
         c.concept_id AS icd_concept_id
  FROM disease_roots dr
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept` c
    ON c.vocabulary_id = 'ICD10CM'
   AND c.concept_code   LIKE CONCAT(dr.root_code, '%')
),

std_maps AS (                     -- 3) Map each ICD concept to its STANDARD concept(s)
  SELECT DISTINCT i.disease,
         cr.concept_id_2 AS std_concept_id
  FROM icd_family i
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` cr
    ON cr.concept_id_1   = i.icd_concept_id
   AND cr.relationship_id = 'Maps to'
),

std_and_desc AS (                 -- 4) Include the STANDARD concepts themselves + ALL their descendants
  SELECT m.disease, m.std_concept_id AS std_concept_id
  FROM std_maps m
  UNION DISTINCT
  SELECT m.disease, ca.descendant_concept_id
  FROM std_maps m
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
    ON ca.ancestor_concept_id = m.std_concept_id
),

condition_std AS (                -- 5) Keep only STANDARD Condition-domain concepts
  SELECT DISTINCT d.disease, c.concept_id
  FROM std_and_desc d
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept` c
    ON c.concept_id       = d.std_concept_id
   AND c.standard_concept = 'S'
   AND c.domain_id        = 'Condition'
),

per_disease AS (                  -- 6) Number of unique participants per disease
  SELECT cs.disease,
         COUNT(DISTINCT co.person_id) AS n_participants
  FROM condition_std cs
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` co
    ON co.condition_concept_id = cs.concept_id
  GROUP BY cs.disease
),

total_n AS (                      -- 7) Total unique participants in the cohort
  SELECT COUNT(DISTINCT person_id) AS total_participants
  FROM (
      SELECT person_id FROM `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`
      UNION DISTINCT
      SELECT person_id FROM `bigquery-public-data.cms_synthetic_patient_data_omop.observation`
      UNION DISTINCT
      SELECT person_id FROM `bigquery-public-data.cms_synthetic_patient_data_omop.procedure_occurrence`
  )
)

SELECT p.disease,
       p.n_participants,
       ROUND(100 * p.n_participants / t.total_participants, 4) AS percent_participants
FROM per_disease p
CROSS JOIN total_n t
ORDER BY percent_participants DESC;