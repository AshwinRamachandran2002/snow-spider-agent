/*  Percentage of participants with acne (L70*), atopic dermatitis (L20*),
    psoriasis (L40*), and vitiligo (L80*).

    Steps
    1)  Pick every ICD-10-CM concept whose code starts with the indicated root.
    2)  Follow the “Maps to” relationship to reach its STANDARD concept(s).
    3)  Add all descendant concepts of those STANDARD concepts
        (concept_ancestor) – these are also STANDARD.
    4)  Count distinct persons appearing in condition_occurrence with any
        of those STANDARD (or descendant) concept_ids.
    5)  Divide by the total number of distinct persons represented in
        condition_occurrence.
*/

WITH roots AS (
  SELECT 'L70' AS root, 'Acne'               AS disorder UNION ALL
  SELECT 'L20',          'Atopic Dermatitis' UNION ALL
  SELECT 'L40',          'Psoriasis'         UNION ALL
  SELECT 'L80',          'Vitiligo'
),

-- 1. ICD-10-CM source concepts for each root
icd AS (
  SELECT r.disorder,
         c.concept_id
  FROM   roots r
  JOIN   `bigquery-public-data.cms_synthetic_patient_data_omop.concept` c
         ON c.vocabulary_id = 'ICD10CM'
        AND c.concept_code LIKE CONCAT(r.root, '%')
),

-- 2. STANDARD concepts those ICD-10-CM codes “map to”
std AS (
  SELECT DISTINCT i.disorder,
         cr.concept_id_2 AS standard_id
  FROM   icd i
  JOIN   `bigquery-public-data.cms_synthetic_patient_data_omop.concept_relationship` cr
         ON cr.concept_id_1 = i.concept_id
        AND cr.relationship_id = 'Maps to'
),

-- 3. STANDARD concepts + all their descendants
std_plus_desc AS (
  SELECT disorder, standard_id AS concept_id
  FROM   std
  UNION ALL
  SELECT s.disorder, ca.descendant_concept_id
  FROM   std s
  JOIN   `bigquery-public-data.cms_synthetic_patient_data_omop.concept_ancestor` ca
         ON ca.ancestor_concept_id = s.standard_id
),

-- 4. People with any of those STANDARD (or descendant) concepts
people AS (
  SELECT DISTINCT spd.disorder, co.person_id
  FROM   std_plus_desc spd
  JOIN   `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence` co
         ON co.condition_concept_id = spd.concept_id
),

-- counts per disorder
n_people AS (
  SELECT disorder, COUNT(DISTINCT person_id) AS n_people
  FROM   people
  GROUP BY disorder
),

-- 5. denominator: all people recorded in condition_occurrence
total_pop AS (
  SELECT COUNT(DISTINCT person_id) AS total_people
  FROM   `bigquery-public-data.cms_synthetic_patient_data_omop.condition_occurrence`
)

SELECT n.disorder,
       n.n_people,
       ROUND(100.0 * n.n_people / t.total_people, 4) AS pct_of_participants
FROM   n_people n
CROSS JOIN total_pop t
ORDER BY n.disorder;