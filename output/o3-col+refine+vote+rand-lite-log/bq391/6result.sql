WITH a_patients AS (               -- living patients whose last name starts with “A”
  SELECT DISTINCT p.id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient` p
  CROSS JOIN UNNEST(p.name) n
  WHERE n.family LIKE 'A%'                       -- surname begins with A
    AND (p.active IS NULL OR p.active = TRUE)    -- treat NULL as living/active
),
patient_conditions AS (           -- all conditions for those patients
  SELECT c.subject.patientId AS patient_id,
         cc.code             AS condition_code,
         cc.display          AS condition_display
  FROM `bigquery-public-data.fhir_synthea.condition` c
  CROSS JOIN UNNEST(c.code.coding) cc
  WHERE c.subject.patientId IN (SELECT patient_id FROM a_patients)
),
condition_counts AS (             -- how many distinct conditions each patient has
  SELECT patient_id,
         COUNT(DISTINCT condition_code) AS cond_cnt
  FROM patient_conditions
  GROUP BY patient_id
),
single_condition_patients AS (    -- keep only patients with exactly one condition
  SELECT DISTINCT pc.patient_id,
         pc.condition_code,
         pc.condition_display
  FROM patient_conditions pc
  JOIN condition_counts cc
    ON pc.patient_id = cc.patient_id
  WHERE cc.cond_cnt = 1
),
patient_med_counts AS (           -- count of different active meds per such patient
  SELECT mr.subject.patientId  AS patient_id,
         COUNT(DISTINCT mc.code) AS active_med_cnt
  FROM `bigquery-public-data.fhir_synthea.medication_request` mr
  CROSS JOIN UNNEST(mr.medication.codeableConcept.coding) mc
  WHERE mr.status = 'active'
    AND mr.subject.patientId IN (SELECT patient_id FROM single_condition_patients)
  GROUP BY patient_id
),
condition_max_meds AS (           -- max active-med count per condition
  SELECT sc.condition_code,
         sc.condition_display,
         MAX(pmc.active_med_cnt) AS max_active_meds_for_any_patient
  FROM single_condition_patients sc
  JOIN patient_med_counts pmc
    ON sc.patient_id = pmc.patient_id
  GROUP BY sc.condition_code,
           sc.condition_display
)
SELECT condition_code,
       condition_display,
       max_active_meds_for_any_patient
FROM condition_max_meds
ORDER BY max_active_meds_for_any_patient DESC
LIMIT 8;