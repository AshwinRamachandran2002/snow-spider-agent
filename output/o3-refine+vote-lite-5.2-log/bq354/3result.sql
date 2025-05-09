/*  Percentage of participants diagnosed with Acne (L70*), 
    Atopic Dermatitis (L20*), Psoriasis (L40*), and Vitiligo (L80*)
    – including all ICD‑10‑CM sub‑categories – in the OMOP synthetic
    patient data set.                                                   */

WITH target_codes AS (
  SELECT 'Acne'               AS disease , 'L70' AS icd_prefix UNION ALL
  SELECT 'Atopic dermatitis'  AS disease , 'L20' UNION ALL
  SELECT 'Psoriasis'          AS disease , 'L40' UNION ALL
  SELECT 'Vitiligo'           AS disease , 'L80'
),

/* 1.  Locate the root ICD‑10‑CM concept_id for each 3‑character code   */
root_concepts AS (
  SELECT
    t.disease ,
    c.concept_id
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.concept` c
  JOIN target_codes t
    ON  c.vocabulary_id = 'ICD10CM'
    AND c.concept_code   = t.icd_prefix
),

/* 2.  Pull every ICD‑10‑CM descendant (sub‑category) under each root   */
icd_descendants AS (
  SELECT
    r.disease ,
    a.descendant_concept_id AS icd_concept_id
  FROM root_concepts            r
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` a
    ON a.ancestor_concept_id = r.concept_id

  UNION DISTINCT                 -- include the root code itself
  SELECT disease , concept_id FROM root_concepts
),

/* 3.  Map every ICD‑10‑CM concept to its standard OMOP concept(s)      */
mapped_standard AS (
  SELECT DISTINCT
    d.disease ,
    cr.concept_id_2            AS standard_concept_id
  FROM icd_descendants                         d
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` cr
    ON  cr.concept_id_1 = d.icd_concept_id
    AND cr.relationship_id = 'Maps to'         -- standard SNOMED etc.
),

/* 4.  Identify all unique persons with any of these standard concepts  */
disease_persons AS (
  SELECT DISTINCT
    m.disease ,
    ce.person_id
  FROM mapped_standard                                  m
  JOIN `bigquery-public-data.cms_synthetic_patient_data_omop.condition_era` ce
    ON ce.condition_concept_id = m.standard_concept_id
),

/* 5.  Count persons per disease                                         */
disease_counts AS (
  SELECT
    disease ,
    COUNT(DISTINCT person_id) AS participant_count
  FROM disease_persons
  GROUP BY disease
),

/* 6.  Total number of participants in the dataset                       */
total_participants AS (
  SELECT COUNT(DISTINCT person_id) AS total_cnt
  FROM `bigquery-public-data.cms_synthetic_patient_data_omop.person`
)

SELECT
  dc.disease ,
  dc.participant_count ,
  ROUND( dc.participant_count / tp.total_cnt * 100 , 4 ) AS percent_of_total
FROM disease_counts       dc
CROSS JOIN total_participants tp
ORDER BY percent_of_total DESC;