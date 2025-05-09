-- Percentage of participants with acne (L70), atopic dermatitis (L20),
-- psoriasis (L40) and vitiligo (L80), including all ICD-10-CM
-- sub-categories → standard concepts and all of their descendant concepts.
WITH
/* 1.  All ICD-10-CM concepts that start with the 4 root codes               */
icd_roots AS (
  SELECT
    concept_id,
    CASE
      WHEN concept_code LIKE 'L20%' THEN 'L20'
      WHEN concept_code LIKE 'L40%' THEN 'L40'
      WHEN concept_code LIKE 'L70%' THEN 'L70'
      WHEN concept_code LIKE 'L80%' THEN 'L80'
    END AS root_code
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'ICD10CM'
    AND concept_code  IN UNNEST(['L20','L40','L70','L80'])  -- grab the 4 root rows themselves
),
/* 2.  Map each ICD-10-CM root to the STANDARD concept(s) via “Maps to”.     */
std_maps AS (
  SELECT DISTINCT
    r.root_code,
    cr.concept_id_2 AS std_concept_id
  FROM icd_roots                r
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` cr
       ON cr.concept_id_1 = r.concept_id
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept` sc
       ON sc.concept_id = cr.concept_id_2
  WHERE cr.relationship_id = 'Maps to'
    AND sc.standard_concept = 'S'                         -- keep only STANDARD targets
),
/* 3.  Grab every STANDARD descendant (including the ancestor itself).       */
std_descendants AS (
  SELECT DISTINCT
    m.root_code,
    ca.descendant_concept_id AS concept_id
  FROM std_maps                                   m
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
       ON ca.ancestor_concept_id = m.std_concept_id
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept` sc
       ON sc.concept_id = ca.descendant_concept_id
  WHERE sc.standard_concept = 'S'                 -- keep only STANDARD descendants
),
/* 4.  Count unique persons per disease group.                               */
persons_per_dx AS (
  SELECT
    d.root_code,
    COUNT(DISTINCT co.person_id) AS n_persons
  FROM std_descendants                                           d
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` co
       ON co.condition_concept_id = d.concept_id
  GROUP BY d.root_code
),
/* 5.  Denominator: all persons with any condition_occurrence record.        */
total_persons AS (
  SELECT COUNT(DISTINCT person_id) AS total_n
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`
)
/* 6.  Final percentages.                                                    */
SELECT
  p.root_code                                     AS disease_group,
  p.n_persons,
  t.total_n                                       AS total_persons,
  ROUND(100 * p.n_persons / t.total_n, 4)         AS pct_participants
FROM persons_per_dx p
CROSS JOIN total_persons t
ORDER BY disease_group;