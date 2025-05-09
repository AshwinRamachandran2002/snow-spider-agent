/*  % of participants diagnosed with acne (L70*), atopic dermatitis (L20*),
    psoriasis (L40*), and vitiligo (L80*), including all ICD‑10‑CM
    sub‑categories.  Only standard concepts (and their descendants) that the
    ICD‑10‑CM codes map to are counted.                                      */

WITH condition_groups AS (
  SELECT 'Acne'               AS condition_name, 'L70' AS icd_prefix UNION ALL
  SELECT 'Atopic Dermatitis'  AS condition_name, 'L20' UNION ALL
  SELECT 'Psoriasis'          AS condition_name, 'L40' UNION ALL
  SELECT 'Vitiligo'           AS condition_name, 'L80'
),

/* 1.  All ICD‑10‑CM codes (non‑standard) that begin with the required prefix */
icd10cm_concepts AS (
  SELECT
    g.condition_name,
    c.concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept` AS c
  JOIN condition_groups AS g
    ON c.vocabulary_id = 'ICD10CM'
   AND c.concept_code   LIKE CONCAT(g.icd_prefix, '%')
   AND c.invalid_reason IS NULL                     -- keep only valid codes
),

/* 2.  Map those ICD‑10‑CM codes to the standard concept(s) (usually SNOMED)
       via the “Maps to” relationship                                           */
mapped_standard AS (
  SELECT DISTINCT
    i.condition_name,
    cr.concept_id_2 AS standard_concept_id
  FROM icd10cm_concepts            AS i
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` AS cr
    ON cr.concept_id_1 = i.concept_id
   AND cr.relationship_id = 'Maps to'
   AND cr.invalid_reason IS NULL
),

/* 3.  Add every descendant of each standard concept (plus the concept itself) */
all_standard_concepts AS (
  -- descendants
  SELECT DISTINCT
    m.condition_name,
    ca.descendant_concept_id AS concept_id
  FROM mapped_standard                        AS m
  LEFT JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` AS ca
    ON ca.ancestor_concept_id = m.standard_concept_id

  UNION DISTINCT

  -- the ancestor (mapped) concepts themselves
  SELECT DISTINCT
    condition_name,
    standard_concept_id
  FROM mapped_standard
),

/* 4.  Count unique persons with at least one matching condition occurrence    */
condition_counts AS (
  SELECT
    s.condition_name,
    COUNT(DISTINCT co.person_id) AS person_cnt
  FROM all_standard_concepts                                       AS s
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` AS co
    ON co.condition_concept_id = s.concept_id
  GROUP BY s.condition_name
),

/* 5.  Total number of persons in the synthetic OMOP dataset                   */
total_persons AS (
  SELECT COUNT(DISTINCT person_id) AS total_cnt
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`
)

SELECT
  cc.condition_name,
  cc.person_cnt                                 AS participants_with_condition,
  tp.total_cnt                                  AS total_participants,
  ROUND(cc.person_cnt * 100.0 / tp.total_cnt, 4) AS percentage_of_participants
FROM condition_counts AS cc
CROSS JOIN total_persons  AS tp
ORDER BY percentage_of_participants DESC;