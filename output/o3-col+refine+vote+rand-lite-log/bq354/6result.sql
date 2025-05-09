/*  Percentage of participants with Acne (L70), Atopic Dermatitis (L20),
    Psoriasis (L40) and Vitiligo (L80) – including all descendant concepts   */

WITH disease_codes AS (           -- ICD-10-CM root codes of interest
  SELECT 'Acne'               AS disease, 'L70' AS icd_root UNION ALL
  SELECT 'Atopic dermatitis', 'L20' UNION ALL
  SELECT 'Psoriasis',         'L40' UNION ALL
  SELECT 'Vitiligo',          'L80'
),

standard_roots AS (          -- map each ICD-10-CM root to its STANDARD concept_id
  SELECT
      dc.disease,
      cr.concept_id_2 AS std_concept_id
  FROM  disease_codes dc
  JOIN  `bigquery-public-data.cms_synthetic_patient_data_omop.concept`            icd
        ON icd.vocabulary_id = 'ICD10CM'
       AND icd.concept_code  = dc.icd_root
  JOIN  `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` cr
        ON cr.concept_id_1   = icd.concept_id
       AND cr.relationship_id = 'Maps to'
  JOIN  `bigquery-public-data.cms_synthetic_patient_data_omop.concept`            std
        ON std.concept_id    = cr.concept_id_2
       AND std.standard_concept = 'S'            -- keep only standard concepts
),

all_descendants AS (         -- collect every descendant concept of each root
  SELECT
      sr.disease,
      ca.descendant_concept_id
  FROM  standard_roots sr
  JOIN  `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
        ON ca.ancestor_concept_id = sr.std_concept_id
),

disease_counts AS (          -- number of distinct participants per disease
  SELECT
      ad.disease,
      COUNT(DISTINCT co.person_id) AS disease_participants
  FROM  all_descendants ad
  JOIN  `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` co
        ON co.condition_concept_id = ad.descendant_concept_id
  GROUP BY ad.disease
),

total_pop AS (               -- total unique participants with any condition
  SELECT COUNT(DISTINCT person_id) AS total_participants
  FROM   `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`
)

SELECT
    dc.disease,
    dc.disease_participants,
    tp.total_participants,
    ROUND(100.0 * dc.disease_participants / tp.total_participants, 4) AS pct_of_participants
FROM   disease_counts dc
CROSS  JOIN total_pop tp
ORDER  BY pct_of_participants DESC;