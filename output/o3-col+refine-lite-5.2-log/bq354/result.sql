/*  Percentage of participants with Acne (L70*), Atopic Dermatitis (L20*),
    Psoriasis (L40*) and Vitiligo (L80*) ICD‑10‑CM diagnoses, using
    all standard descendant concepts.                                             */

WITH roots AS (                       -- codes of interest
  SELECT 'L70' AS root_code, 'Acne'               AS disorder UNION ALL
  SELECT 'L20',              'Atopic Dermatitis'  UNION ALL
  SELECT 'L40',              'Psoriasis'          UNION ALL
  SELECT 'L80',              'Vitiligo'
),

/* Root concept_id for each 3‑character ICD‑10‑CM code (standard, valid) */
root_concept_ids AS (
  SELECT r.root_code,
         r.disorder,
         c.concept_id
  FROM   roots r
  JOIN   `bigquery-public-data.cms_synthetic_patient_data_omop.concept` c
         ON  c.vocabulary_id   = 'ICD10CM'
         AND c.standard_concept = 'S'
         AND c.invalid_reason  IS NULL
         AND c.concept_code    = r.root_code
),

/* All standard descendant concepts (including the root itself)            */
descendant_concepts AS (
  SELECT DISTINCT
         rc.root_code,
         rc.disorder,
         d.concept_id
  FROM   root_concept_ids rc
  JOIN   `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
           ON ca.ancestor_concept_id = rc.concept_id
  JOIN   `bigquery-public-data.cms_synthetic_patient_data_omop.concept` d
           ON d.concept_id       = ca.descendant_concept_id
          AND d.vocabulary_id    = 'ICD10CM'
          AND d.standard_concept = 'S'
          AND d.invalid_reason   IS NULL

  UNION DISTINCT                       -- ensure the root itself is included
  SELECT rc.root_code,
         rc.disorder,
         rc.concept_id
  FROM   root_concept_ids rc
),

/* Count distinct persons having any of the concepts for each disorder     */
persons_per_disorder AS (
  SELECT  dc.root_code,
          dc.disorder,
          COUNT(DISTINCT co.person_id) AS persons_with_condition
  FROM    descendant_concepts dc
  JOIN    `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` co
            ON co.condition_concept_id = dc.concept_id
  GROUP BY dc.root_code, dc.disorder
),

/* Total number of participants in the synthetic dataset                   */
total_participants AS (
  SELECT COUNT(DISTINCT person_id) AS total_n
  FROM   `bigquery-public-data.cms_synthetic_patient_data_omop.person`
)

SELECT
  r.root_code               AS icd10cm_root_code,
  r.disorder,
  COALESCE(p.persons_with_condition, 0)       AS persons_with_condition,
  t.total_n                                   AS total_participants,
  ROUND(100 * COALESCE(p.persons_with_condition,0) / t.total_n, 4)
                                            AS pct_participants
FROM      roots r
LEFT JOIN persons_per_disorder p  USING (root_code, disorder)
CROSS JOIN total_participants t
ORDER BY  r.root_code;