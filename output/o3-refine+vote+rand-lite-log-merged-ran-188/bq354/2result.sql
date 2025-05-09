/*  Percentage of participants with Acne (L70*), Atopic Dermatitis (L20*),
    Psoriasis (L40*), and Vitiligo (L80*), including all mapped STANDARD
    concepts and their descendants                                       */

WITH target_roots AS (                 -- ICD-10-CM code roots of interest
  SELECT 'L70' AS root UNION ALL
  SELECT 'L20' UNION ALL
  SELECT 'L40' UNION ALL
  SELECT 'L80'
),

icd10 AS (                             -- all ICD-10-CM concepts for those roots
  SELECT
    c.concept_id,
    SUBSTR(c.concept_code,1,3) AS root
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept` AS c
  WHERE c.vocabulary_id = 'ICD10CM'
    AND SUBSTR(c.concept_code,1,3) IN (SELECT root FROM target_roots)
),

std AS (                               -- map to STANDARD concepts (usually SNOMED)
  SELECT DISTINCT
    i.root,
    r.concept_id_2 AS standard_concept_id
  FROM icd10                       AS i
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` AS r
    ON r.concept_id_1 = i.concept_id
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept` AS c_std
    ON c_std.concept_id = r.concept_id_2
  WHERE r.relationship_id = 'Maps to'
    AND c_std.standard_concept = 'S'      -- keep only standard target concepts
),

all_desc AS (                           -- include every descendant (incl. self)
  SELECT
    s.root,
    ca.descendant_concept_id
  FROM std AS s
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` AS ca
    ON ca.ancestor_concept_id = s.standard_concept_id
),

patient_counts AS (                     -- distinct participants per disease root
  SELECT
    ad.root                           AS icd10_root,
    COUNT(DISTINCT co.person_id)      AS participant_cnt
  FROM all_desc                       AS ad
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` AS co
    ON co.condition_concept_id = ad.descendant_concept_id
  GROUP BY ad.root
),

total_participants AS (                 -- denominator
  SELECT COUNT(DISTINCT person_id) AS total_cnt
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`
)

SELECT
  pc.icd10_root                                   AS icd10_code_root,
  pc.participant_cnt                              AS participants,
  tp.total_cnt                                    AS total_participants,
  ROUND(100.0 * pc.participant_cnt / tp.total_cnt, 4) AS percentage_of_participants
FROM patient_counts     AS pc
CROSS JOIN total_participants AS tp
ORDER BY icd10_code_root;