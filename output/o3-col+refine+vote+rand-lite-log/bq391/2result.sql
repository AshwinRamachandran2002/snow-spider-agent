/*  Eight conditions whose single-condition “A-surname” patients
    have the highest count of distinct prescribed medications          */

WITH a_patients AS (          -- patients whose last name starts with “A”
  SELECT DISTINCT p.id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient` AS p
  CROSS JOIN UNNEST(p.name) AS n
  WHERE n.family LIKE 'A%'
),
one_condition_patients AS (   -- keep only patients with exactly one condition
  SELECT c.subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  WHERE c.subject.patientId IN (SELECT patient_id FROM a_patients)
  GROUP BY patient_id
  HAVING COUNT(DISTINCT c.id) = 1
),
patient_med_counts AS (       -- number of distinct meds per patient
  SELECT
    mr.subject.patientId AS patient_id,
    COUNT(DISTINCT mc.code) AS med_cnt
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr
  CROSS JOIN UNNEST(mr.medication.codeableConcept.coding) AS mc
  WHERE mr.subject.patientId IN (SELECT patient_id FROM one_condition_patients)
  GROUP BY patient_id
),
patient_condition AS (        -- each patient’s single condition
  SELECT
    c.subject.patientId AS patient_id,
    cc.code             AS condition_code,
    cc.display          AS condition_name
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  CROSS JOIN UNNEST(c.code.coding) AS cc
  WHERE c.subject.patientId IN (SELECT patient_id FROM one_condition_patients)
)

SELECT
  pc.condition_code,
  pc.condition_name,
  MAX(pm.med_cnt) AS max_medications
FROM patient_condition AS pc
JOIN patient_med_counts AS pm
  ON pc.patient_id = pm.patient_id
GROUP BY pc.condition_code, pc.condition_name
ORDER BY max_medications DESC
LIMIT 8;