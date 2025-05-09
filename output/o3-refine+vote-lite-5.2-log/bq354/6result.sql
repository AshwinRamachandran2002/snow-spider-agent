WITH icd10_categories AS (
  SELECT 'Acne'                AS disease, 'L70' AS prefix UNION ALL
  SELECT 'Atopic Dermatitis'   AS disease, 'L20' AS prefix UNION ALL
  SELECT 'Psoriasis'           AS disease, 'L40' AS prefix UNION ALL
  SELECT 'Vitiligo'            AS disease, 'L80' AS prefix
),
-- 1.  All ICD‑10‑CM source concepts that start with each prefix (includes sub‑categories)
icd10_source_concepts AS (
  SELECT 
    cat.disease,
    c.concept_id
  FROM icd10_categories cat
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept`  c
       ON  c.vocabulary_id = 'ICD10CM'
       AND c.concept_code  LIKE CONCAT(cat.prefix, '%')
),
-- 2.  Map every source concept to its STANDARD concept(s)
std_concepts AS (
  SELECT DISTINCT
    src.disease,
    rel.concept_id_2 AS standard_concept_id
  FROM icd10_source_concepts  src
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` rel
       ON  rel.concept_id_1  = src.concept_id
       AND rel.relationship_id = 'Maps to'
),
-- 3.  Persons having any of those STANDARD concepts recorded
cases AS (
  SELECT DISTINCT
    std.disease,
    cond.person_id
  FROM std_concepts                                           std
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`  cond
       ON cond.condition_concept_id = std.standard_concept_id
),
-- 4.  Count persons per disease
disease_counts AS (
  SELECT
    disease,
    COUNT(DISTINCT person_id) AS person_cnt
  FROM cases
  GROUP BY disease
),
-- 5.  Total number of participants in the dataset
all_participants AS (
  SELECT COUNT(DISTINCT person_id) AS total_cnt
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`
)
-- 6.  Final percentages
SELECT
  dc.disease,
  dc.person_cnt                               AS participants,
  ap.total_cnt                                AS total_participants,
  ROUND(dc.person_cnt / ap.total_cnt * 100,4) AS percent_of_participants
FROM disease_counts dc
CROSS JOIN all_participants ap
ORDER BY dc.disease;