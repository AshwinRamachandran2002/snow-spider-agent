SELECT
  COUNT(DISTINCT p.id) AS alive_diab_or_htn_with_7plus_active_meds
FROM `bigquery-public-data.fhir_synthea.patient` AS p
JOIN (
  -- patients with a diagnosis that mentions Diabetes or Hypertension
  SELECT DISTINCT subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition`
  WHERE LOWER(code.text) LIKE '%diabetes%'
     OR LOWER(code.text) LIKE '%hypertension%'
) AS dx
  ON p.id = dx.patient_id
JOIN (
  -- patients with ≥ 7 distinct active medications
  SELECT
    subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.medication_request`
  WHERE status = 'active'
  GROUP BY patient_id
  HAVING COUNT(DISTINCT medication.codeableConcept.coding[OFFSET(0)].code) >= 7
) AS meds
  ON p.id = meds.patient_id
WHERE p.deceased.dateTime IS NULL;