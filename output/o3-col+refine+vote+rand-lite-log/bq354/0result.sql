WITH disease_prefix AS (
  SELECT 'Acne'               AS disease, 'L70' AS prefix UNION ALL
  SELECT 'Atopic Dermatitis', 'L20'             UNION ALL
  SELECT 'Psoriasis',          'L40'            UNION ALL
  SELECT 'Vitiligo',           'L80'
),

/* 1.  All ICD-10-CM concepts that begin with the requested prefix */
icd10cm_concepts AS (
  SELECT dp.disease,
         c.concept_id
  FROM   disease_prefix dp
  JOIN   `bigquery-public-data.cms_synthetic_patient_data_omop.concept` AS c
    ON   c.vocabulary_id = 'ICD10CM'
   AND   c.concept_code  LIKE CONCAT(dp.prefix, '%')
),

/* 2.  Map each ICD-10-CM concept to its standard SNOMED/OMOP concept(s) */
standard_concepts AS (
  SELECT DISTINCT i.disease,
         cr.concept_id_2 AS standard_concept_id
  FROM   icd10cm_concepts                   AS i
  JOIN   `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` cr
         ON i.concept_id = cr.concept_id_1
  JOIN   `bigquery-public-data.cms_synthetic_patient_data_omop.concept` sc
         ON cr.concept_id_2 = sc.concept_id
  WHERE  cr.relationship_id = 'Maps to'
    AND  sc.standard_concept = 'S'          -- keep only standard concepts
),

/* 3.  Add every descendant of each standard concept, plus the concept itself */
all_related_concepts AS (
  SELECT DISTINCT s.disease,
         ca.descendant_concept_id AS concept_id
  FROM   standard_concepts AS s
  JOIN   `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
         ON s.standard_concept_id = ca.ancestor_concept_id
  
  UNION DISTINCT
  
  SELECT disease,
         standard_concept_id
  FROM   standard_concepts
),

/* 4.  Identify participants with any of those related concepts */
disease_persons AS (
  SELECT arc.disease,
         co.person_id
  FROM   all_related_concepts                                         AS arc
  JOIN   `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` co
         ON co.condition_concept_id = arc.concept_id
  GROUP BY arc.disease, co.person_id      -- ensure uniqueness per disease
),

/* 5.  Total number of distinct participants recorded in condition_occurrence */
denominator AS (
  SELECT COUNT(DISTINCT person_id) AS total_participants
  FROM   `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`
)

/* 6.  Final counts & percentages */
SELECT dp.disease,
       COUNT(DISTINCT dp.person_id)                                         AS participants,
       d.total_participants,
       ROUND(100 * COUNT(DISTINCT dp.person_id) / d.total_participants, 4)  AS percent_participants
FROM   disease_persons AS dp
CROSS JOIN denominator  AS d
GROUP BY dp.disease, d.total_participants
ORDER BY dp.disease;