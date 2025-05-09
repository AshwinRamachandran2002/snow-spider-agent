/*  Top‑8 single‑condition diagnoses (for living “A*” patients with exactly
    one condition) ranked by the greatest number of different ACTIVE
    medications any one such patient is taking.                               */

WITH patients_a AS (                -- living patients, surname starts with “A”
  SELECT DISTINCT p.id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient` p
  CROSS JOIN UNNEST(p.name) n
  WHERE p.deceased IS NULL
    AND n.family IS NOT NULL
    AND STARTS_WITH(UPPER(n.family), 'A')
),

patient_conditions AS (             -- all conditions for those patients
  SELECT
    c.subject.patientId            AS patient_id,
    cd.code                        AS condition_code,
    cd.display                     AS condition_display
  FROM `bigquery-public-data.fhir_synthea.condition` c
  CROSS JOIN UNNEST(c.code.coding) cd
  WHERE c.subject.patientId IN (SELECT patient_id FROM patients_a)
),

single_condition_patients AS (      -- keep only patients with ONE condition
  SELECT DISTINCT patient_id, condition_code, condition_display
  FROM (
    SELECT pc.*,
           COUNT(DISTINCT condition_code)
             OVER (PARTITION BY patient_id) AS cond_cnt
    FROM patient_conditions pc
  )
  WHERE cond_cnt = 1
),

active_meds AS (                    -- ACTIVE medications for those patients
  SELECT
    mr.subject.patientId AS patient_id,
    mc.code              AS med_code
  FROM `bigquery-public-data.fhir_synthea.medication_request` mr
  CROSS JOIN UNNEST(IFNULL(mr.medication.codeableConcept.coding, [])) mc
  WHERE mr.status = 'active'
    AND mr.subject.patientId IN (SELECT patient_id FROM single_condition_patients)
),

per_patient_med_counts AS (         -- #distinct active meds per patient
  SELECT
    sc.condition_code,
    sc.condition_display,
    sc.patient_id,
    COUNT(DISTINCT am.med_code) AS med_cnt
  FROM single_condition_patients sc
  LEFT JOIN active_meds am
    ON am.patient_id = sc.patient_id
  GROUP BY sc.condition_code, sc.condition_display, sc.patient_id
),

condition_best_cnt AS (             -- max #meds observed for each condition
  SELECT
    condition_code,
    condition_display,
    MAX(med_cnt) AS max_distinct_active_meds
  FROM per_patient_med_counts
  GROUP BY condition_code, condition_display
)

SELECT
  condition_display AS condition,
  condition_code    AS code,
  max_distinct_active_meds
FROM condition_best_cnt
ORDER BY max_distinct_active_meds DESC, condition_code
LIMIT 8;