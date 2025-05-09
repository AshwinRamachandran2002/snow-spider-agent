WITH patients_a AS (
  -- living patients whose last name starts with "A"
  SELECT
    p.id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient` AS p
  LEFT JOIN UNNEST(p.name) AS n
  WHERE p.deceased IS NULL
    AND LOWER(SUBSTR(n.family, 1, 1)) = 'a'
),
patient_conditions AS (
  -- every (patient, condition code) pair
  SELECT
    c.subject.patientId           AS patient_id,
    cc.code                       AS condition_code
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  LEFT JOIN UNNEST(c.code.coding) AS cc
  WHERE cc.code IS NOT NULL
),
patients_one_condition AS (
  -- keep only patients (from patients_a) who have exactly ONE distinct condition
  SELECT
    pc.patient_id,
    MIN(pc.condition_code) AS condition_code      -- the single condition code they have
  FROM patient_conditions pc
  JOIN patients_a          pa ON pa.patient_id = pc.patient_id
  GROUP BY pc.patient_id
  HAVING COUNT(DISTINCT pc.condition_code) = 1
),
active_meds AS (
  -- active medications per patient
  SELECT
    mr.subject.patientId                         AS patient_id,
    mc.code                                      AS med_code
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr
  LEFT JOIN UNNEST(mr.medication.codeableConcept.coding) AS mc
  WHERE mr.status = 'active'
    AND mc.code IS NOT NULL
),
patient_med_counts AS (
  -- number of distinct active meds for each (patient, condition)
  SELECT
    p.patient_id,
    p.condition_code,
    COUNT(DISTINCT a.med_code) AS active_med_cnt
  FROM patients_one_condition p
  LEFT JOIN active_meds       a ON a.patient_id = p.patient_id
  GROUP BY p.patient_id, p.condition_code
),
condition_stats AS (
  -- for each condition: the maximum count seen in any single patient
  SELECT
    condition_code,
    MAX(active_med_cnt) AS max_active_meds
  FROM patient_med_counts
  GROUP BY condition_code
)
-- top eight conditions by that maximum
SELECT
  condition_code,
  max_active_meds
FROM condition_stats
ORDER BY max_active_meds DESC, condition_code
LIMIT 8;