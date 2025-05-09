/*  Percentage of participants with acne, atopic dermatitis, psoriasis, and vitiligo
    (ICD‑10‑CM chapters L70, L20, L40, L80 and all of their sub‑codes)

    Logic:
    1.  Get every ICD‑10‑CM concept whose code starts with the required prefix.
    2.  Follow “Maps to” relationships to the STANDARD condition concepts
        (usually SNOMED CT) those ICD codes map to.
    3.  Add every DESCENDANT of those standard concepts (plus the concepts
        themselves) through the concept_ancestor table.
    4.  Count distinct persons in condition_occurrence with any of those
        concepts for each disease category.
    5.  Divide by the total number of distinct persons in the OMOP PERSON table.
*/

WITH category_prefixes AS (
  SELECT 'Acne'              AS category, 'L70' AS icd_prefix UNION ALL
  SELECT 'Atopic Dermatitis' AS category, 'L20' AS icd_prefix UNION ALL
  SELECT 'Psoriasis'         AS category, 'L40' AS icd_prefix UNION ALL
  SELECT 'Vitiligo'          AS category, 'L80' AS icd_prefix
),

-- 1.  All ICD‑10‑CM source concepts (non‑standard) for each prefix
icd10cm_concepts AS (
  SELECT
    cp.category,
    c.concept_id
  FROM category_prefixes cp
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept` c
    ON c.vocabulary_id = 'ICD10CM'
   AND c.concept_code LIKE CONCAT(cp.icd_prefix, '%')
),

-- 2.  Standard CONDITION concepts those ICD codes map to
std_condition_concepts AS (
  SELECT DISTINCT
    ic.category,
    cr.concept_id_2 AS standard_concept_id
  FROM icd10cm_concepts             ic
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` cr
       ON cr.concept_id_1 = ic.concept_id
      AND cr.relationship_id = 'Maps to'
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept` sc
       ON sc.concept_id = cr.concept_id_2
      AND sc.standard_concept = 'S'
      AND sc.domain_id       = 'Condition'
),

-- 3.  Add every descendant (and the concept itself) of the standard concepts
condition_concept_set AS (
  SELECT DISTINCT
    category,
    descendant_concept_id AS concept_id
  FROM std_condition_concepts scc
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
       ON ca.ancestor_concept_id = scc.standard_concept_id
  UNION DISTINCT
  SELECT
    category,
    standard_concept_id AS concept_id
  FROM std_condition_concepts
),

-- 4.  Distinct persons per category who have at least one matching condition
persons_per_category AS (
  SELECT DISTINCT
    ccs.category,
    co.person_id
  FROM condition_concept_set                                        ccs
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` co
       ON co.condition_concept_id = ccs.concept_id
),

category_counts AS (
  SELECT
    category,
    COUNT(DISTINCT person_id) AS participant_count
  FROM persons_per_category
  GROUP BY category
),

-- total population in the synthetic OMOP dataset
total_pop AS (
  SELECT COUNT(DISTINCT person_id) AS total_persons
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`
)

-- 5.  Final percentage for each disease group
SELECT
  cc.category,
  cc.participant_count,
  ROUND(cc.participant_count / tp.total_persons * 100, 4) AS percentage_of_participants
FROM category_counts cc
CROSS JOIN total_pop tp
ORDER BY cc.category;