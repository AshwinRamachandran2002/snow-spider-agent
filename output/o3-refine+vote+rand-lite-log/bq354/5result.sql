/*----------------------------------------------------------------------
  Percentage of participants with ICD‑10‑CM conditions
  L70 (acne), L20 (atopic dermatitis), L40 (psoriasis), L80 (vitiligo)
  – based on standard concepts and ALL their descendant concepts
----------------------------------------------------------------------*/
WITH base_codes AS (
  SELECT 'L70' AS icd_prefix UNION ALL
  SELECT 'L20' UNION ALL
  SELECT 'L40' UNION ALL
  SELECT 'L80'
),

/* exact top‑level non‑standard ICD‑10‑CM concepts                    */
icd10_top AS (
  SELECT b.icd_prefix,
         c.concept_id AS icd10_concept_id
  FROM  base_codes b
  JOIN  `bigquery-public-data.cms_synthetic_patient_data_omop.concept` c
        ON  c.vocabulary_id = 'ICD10CM'
        AND c.domain_id     = 'Condition'
        AND c.concept_code  = b.icd_prefix
),

/* map each ICD‑10‑CM concept to its STANDARD concept (SNOMED)        */
mapped_std AS (
  SELECT DISTINCT
         i.icd_prefix,
         cr.concept_id_2 AS std_ancestor_id
  FROM  icd10_top i
  JOIN  `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` cr
        ON  cr.concept_id_1   = i.icd10_concept_id
        AND cr.relationship_id = 'Maps to'
        AND cr.invalid_reason IS NULL
),

/* collect ALL descendants (including self) of the mapped std concept */
std_descendants AS (
  SELECT
    m.icd_prefix,
    ca.descendant_concept_id AS std_concept_id
  FROM  mapped_std m
  JOIN  `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
        ON ca.ancestor_concept_id = m.std_ancestor_id
),

/* persons having any of those standard concepts in condition table   */
condition_persons AS (
  SELECT DISTINCT
         d.icd_prefix,
         co.person_id
  FROM  std_descendants d
  JOIN  `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` co
        ON  co.condition_concept_id = d.std_concept_id
),

/* counts per disease                                                 */
disease_counts AS (
  SELECT
    icd_prefix,
    COUNT(DISTINCT person_id) AS patient_cnt
  FROM condition_persons
  GROUP BY icd_prefix
),

/* total distinct persons in the database                             */
total_persons AS (
  SELECT COUNT(DISTINCT person_id) AS total_cnt
  FROM   `bigquery-public-data.cms_synthetic_patient_data_omop.person`
)

SELECT
  dc.icd_prefix AS icd10_code,
  dc.patient_cnt,
  ROUND(100 * dc.patient_cnt / tp.total_cnt, 4) AS percentage_of_participants
FROM disease_counts dc
CROSS JOIN total_persons tp
ORDER BY icd10_code;