WITH alive_patients AS (
  SELECT id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient`
  WHERE deceased.dateTime IS NULL
),
dx_patients AS (
  SELECT DISTINCT c.subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  CROSS JOIN UNNEST(c.code.coding) AS cod
  WHERE LOWER(cod.display) LIKE '%diabetes%'
     OR LOWER(cod.display) LIKE '%hypertension%'
),
polypharmacy AS (
  SELECT mr.subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr
  CROSS JOIN UNNEST(mr.medication.codeableConcept.coding) AS med
  WHERE mr.status = 'active'
  GROUP BY mr.subject.patientId
  HAVING COUNT(DISTINCT med.code) >= 7
)
SELECT
  'alive_diabetes_or_hypertension_7plus_active_meds' AS criteria,
  COUNT(*) AS count
FROM alive_patients
JOIN dx_patients  USING (patient_id)
JOIN polypharmacy USING (patient_id);