-- Patients who are alive AND have Diabetes or Hypertension AND ≥7 distinct active medications
WITH alive_patients AS (
  SELECT pat.id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient` AS pat
  WHERE pat.deceased.dateTime IS NULL
),
diabetes_htn_dx AS (
  SELECT DISTINCT cond.subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition` AS cond
  CROSS JOIN UNNEST(cond.code.coding) AS c
  WHERE LOWER(cond.code.text) LIKE '%diabetes%'      OR LOWER(cond.code.text) LIKE '%hypertension%'
     OR LOWER(c.display)        LIKE '%diabetes%'    OR LOWER(c.display)      LIKE '%hypertension%'
),
polypharmacy AS (
  SELECT mrq.subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS mrq
  CROSS JOIN UNNEST(mrq.medication.codeableConcept.coding) AS med
  WHERE mrq.status = 'active'
  GROUP BY patient_id
  HAVING COUNT(DISTINCT med.code) >= 7
)

SELECT COUNT(DISTINCT p.patient_id) AS alive_diabetes_htn_polypharm_count
FROM alive_patients  AS p
JOIN diabetes_htn_dx AS d  USING (patient_id)
JOIN polypharmacy    AS m  USING (patient_id);