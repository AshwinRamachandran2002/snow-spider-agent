-- Patients who are alive, have Diabetes or Hypertension, and take ≥ 7 distinct active medications
WITH alive AS (
  SELECT
    id AS patientId
  FROM `bigquery-public-data.fhir_synthea.patient`
  WHERE deceased.dateTime IS NULL            -- no recorded date of death
),
dx AS (
  SELECT DISTINCT
    subject.patientId
  FROM `bigquery-public-data.fhir_synthea.condition`
  WHERE LOWER(code.text) LIKE '%diab%'       -- Diabetes
     OR LOWER(code.text) LIKE '%hypert%'     -- Hypertension
),
polypharm AS (
  SELECT
    subject.patientId
  FROM `bigquery-public-data.fhir_synthea.medication_request`
  WHERE status = 'active'                    -- currently active prescriptions
  GROUP BY subject.patientId
  HAVING COUNT(DISTINCT medication.codeableConcept.text) >= 7   -- ≥ 7 distinct meds
)
SELECT
  COUNT(DISTINCT patientId) AS alive_diab_or_htn_with_7plus_meds
FROM alive
JOIN dx USING (patientId)
JOIN polypharm USING (patientId);