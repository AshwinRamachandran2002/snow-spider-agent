/*  Percentage of participants with acne (L70), atopic dermatitis (L20), 
    psoriasis (L40) and vitiligo (L80), including all ICD-10-CM
    sub-codes → standard concepts → all descendants              */

WITH root_icd10 AS (          -- 1. All ICD-10-CM codes that begin with L20/L40/L70/L80
  SELECT
    concept_id                         AS icd_concept_id,
    CASE
      WHEN concept_code LIKE 'L20%' THEN 'Atopic dermatitis (L20)'
      WHEN concept_code LIKE 'L40%' THEN 'Psoriasis (L40)'
      WHEN concept_code LIKE 'L70%' THEN 'Acne (L70)'
      WHEN concept_code LIKE 'L80%' THEN 'Vitiligo (L80)'
    END                                AS condition_family
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE vocabulary_id = 'ICD10CM'
    AND (concept_code LIKE 'L20%' OR
         concept_code LIKE 'L40%' OR
         concept_code LIKE 'L70%' OR
         concept_code LIKE 'L80%')
),

icd_to_standard AS (          -- 2. Map every ICD-10-CM code to its STANDARD concept(s)
  SELECT
    r.condition_family,
    cr.concept_id_2               AS standard_concept_id          -- (usually SNOMED)
  FROM root_icd10         AS r
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` AS cr
    ON cr.concept_id_1     = r.icd_concept_id
   AND cr.relationship_id  = 'Maps to'        -- ICD-10-CM → Standard
   AND cr.concept_id_2    != 0
),

all_descendants AS (          -- 3. Pull every descendant (incl. self) of each standard concept
  SELECT DISTINCT
    i.condition_family,
    ca.descendant_concept_id AS standard_descendant_concept_id
  FROM icd_to_standard AS i
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` AS ca
    ON ca.ancestor_concept_id = i.standard_concept_id           -- includes ancestor itself
),

family_persons AS (           -- 4. Participants that have ≥1 qualifying condition record
  SELECT DISTINCT
    d.condition_family,
    co.person_id
  FROM all_descendants AS d
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` AS co
    ON co.condition_concept_id = d.standard_descendant_concept_id
),

family_counts AS (            -- 5. # participants per family
  SELECT
    condition_family,
    COUNT(DISTINCT person_id) AS n_participants
  FROM family_persons
  GROUP BY condition_family
),

total_participants AS (       -- 6. Denominator = all persons with ≥1 condition record
  SELECT COUNT(DISTINCT person_id) AS total_participants
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`
)

-- 7. Final percentages
SELECT
  f.condition_family,
  f.n_participants,
  t.total_participants,
  ROUND(100 * f.n_participants / t.total_participants, 4) AS pct_participants
FROM family_counts         AS f
CROSS JOIN total_participants AS t
ORDER BY pct_participants DESC;