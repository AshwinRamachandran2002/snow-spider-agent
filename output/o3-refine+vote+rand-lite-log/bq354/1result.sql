/*  % of participants that ever had acne (L70*), atopic dermatitis (L20*),
    psoriasis (L40*) or vitiligo (L80*).
    Steps
      1.  Grab every ICD‑10‑CM concept whose code starts with L70/L20/L40/L80.
      2.  Move from those “classification” concepts to their mapped
          STANDARD concepts (SNOMED) via relationship_id = 'Maps to'.
      3.  Add every descendant of the mapped standard concept
          (concept_ancestor) so that all specific SNOMED children are covered.
      4.  Count distinct persons with ≥1 matching CONDITION_OCCURRENCE record.
      5.  Divide by the total number of persons in the OMOP dataset.           */

WITH icd10_roots AS (
  -- all ICD‑10‑CM concepts beginning with the requested 3‑character stem
  SELECT 'Acne'  AS disease, concept_id
  FROM   `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE  vocabulary_id = 'ICD10CM' AND concept_code LIKE 'L70%'

  UNION ALL
  SELECT 'Atopic Dermatitis', concept_id
  FROM   `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE  vocabulary_id = 'ICD10CM' AND concept_code LIKE 'L20%'

  UNION ALL
  SELECT 'Psoriasis', concept_id
  FROM   `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE  vocabulary_id = 'ICD10CM' AND concept_code LIKE 'L40%'

  UNION ALL
  SELECT 'Vitiligo', concept_id
  FROM   `bigquery-public-data.cms_synthetic_patient_data_omop.concept`
  WHERE  vocabulary_id = 'ICD10CM' AND concept_code LIKE 'L80%'
),

-- map those ICD‑10‑CM codes to STANDARD (SNOMED) concepts
mapped_std AS (
  SELECT DISTINCT ir.disease,
         cr.concept_id_2 AS std_concept_id
  FROM   icd10_roots                  ir
  JOIN   `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` cr
         ON  cr.concept_id_1   = ir.concept_id
         AND cr.relationship_id = 'Maps to'
),

-- include every descendant of each standard concept (self included)
std_with_descendants AS (
  SELECT DISTINCT ms.disease,
         ca.descendant_concept_id AS std_concept_id
  FROM   mapped_std                           ms
  JOIN   `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
         ON  ca.ancestor_concept_id = ms.std_concept_id
),

-- persons who ever had one of those standard concepts recorded
disease_persons AS (
  SELECT DISTINCT swd.disease,
         co.person_id
  FROM   std_with_descendants swd
  JOIN   `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` co
         ON  co.condition_concept_id = swd.std_concept_id
),

disease_counts AS (
  SELECT disease,
         COUNT(DISTINCT person_id) AS participant_cnt
  FROM   disease_persons
  GROUP  BY disease
),

total_participants AS (
  SELECT COUNT(DISTINCT person_id) AS total_cnt
  FROM   `bigquery-public-data.cms_synthetic_patient_data_omop.person`
)

SELECT dc.disease,
       dc.participant_cnt,
       tp.total_cnt,
       ROUND(100 * dc.participant_cnt / tp.total_cnt , 4) AS percent_participants
FROM   disease_counts dc
CROSS  JOIN total_participants tp
ORDER  BY dc.disease;