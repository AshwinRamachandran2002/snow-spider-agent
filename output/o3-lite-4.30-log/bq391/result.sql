WITH living_a_patients AS (                 -- living patients whose last name starts with "A"
  SELECT DISTINCT p.id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient` AS p
  CROSS JOIN UNNEST(p.name) AS n
  WHERE n.family LIKE 'A%'
    AND ( (p.deceased.boolean IS NULL OR p.deceased.boolean = FALSE)
          AND p.deceased.dateTime IS NULL )
),
patient_condition_counts AS (               -- number of distinct conditions per patient
  SELECT c.subject.patientId AS patient_id,
         COUNT(DISTINCT c.code.coding[OFFSET(0)].code) AS num_conditions
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  JOIN living_a_patients lap
    ON lap.patient_id = c.subject.patientId
  GROUP BY patient_id
),
single_condition_patients AS (              -- keep patients with exactly one condition
  SELECT patient_id
  FROM patient_condition_counts
  WHERE num_conditions = 1
),
patient_condition AS (                      -- that single condition for each patient
  SELECT DISTINCT
         c.subject.patientId            AS patient_id,
         c.code.coding[OFFSET(0)].code  AS condition_code,
         c.code.text                    AS condition_text
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  JOIN single_condition_patients scp
    ON scp.patient_id = c.subject.patientId
),
patient_active_meds AS (                    -- #distinct active meds per patient
  SELECT
    mr.subject.patientId                 AS patient_id,
    COUNT(DISTINCT med.code)             AS num_active_meds
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr
  JOIN single_condition_patients scp
    ON scp.patient_id = mr.subject.patientId
  CROSS JOIN UNNEST(IFNULL(mr.medication.codeableConcept.coding, [])) AS med
  WHERE mr.status = 'active'
  GROUP BY patient_id
),
condition_med_counts AS (                   -- max meds per condition across patients
  SELECT
    pc.condition_code,
    pc.condition_text,
    MAX(pam.num_active_meds) AS max_active_meds_per_patient
  FROM patient_condition pc
  JOIN patient_active_meds pam
    ON pam.patient_id = pc.patient_id
  GROUP BY pc.condition_code, pc.condition_text
)
SELECT
  condition_text AS condition,
  condition_code AS code
FROM condition_med_counts
ORDER BY max_active_meds_per_patient DESC, code
LIMIT 8;