SELECT COUNT(DISTINCT alive_patients.patient_id) AS Number_of_Patients
FROM
(
  -- Alive patients
  SELECT id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient`
  WHERE deceased.dateTime IS NULL
) AS alive_patients
JOIN
(
  -- Patients with Diabetes or Hypertension
  SELECT DISTINCT subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition` AS c,
  UNNEST(c.code.coding) AS coding
  WHERE LOWER(coding.display) LIKE '%diabetes%' OR LOWER(coding.display) LIKE '%hypertension%'
) AS condition_patients
ON alive_patients.patient_id = condition_patients.patient_id
JOIN
(
  -- Patients with at least seven distinct active medications
  SELECT subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr,
  UNNEST(mr.medication.codeableConcept.coding) AS med_coding
  WHERE mr.status = 'active' AND med_coding.code IS NOT NULL
  GROUP BY subject.patientId
  HAVING COUNT(DISTINCT med_coding.code) >= 7
) AS medication_patients
ON alive_patients.patient_id = medication_patients.patient_id;