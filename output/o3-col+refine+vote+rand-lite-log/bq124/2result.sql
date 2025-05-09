-- Number of living* patients diagnosed with Diabetes OR Hypertension
-- who have ≥7 distinct active medications
WITH alive AS (
  SELECT
    id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient`
  WHERE (deceased.boolean IS NULL OR deceased.boolean = FALSE)   -- not marked deceased
    AND deceased.dateTime IS NULL                                -- no death date recorded
),
diagnosed AS (
  SELECT DISTINCT
    c.subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  CROSS JOIN UNNEST(c.code.coding) AS cod
  WHERE LOWER(c.code.text)  LIKE '%diabetes%'     OR LOWER(cod.display) LIKE '%diabetes%'
     OR LOWER(c.code.text)  LIKE '%hypertension%' OR LOWER(cod.display) LIKE '%hypertension%'
),
polypharmacy AS (
  SELECT
    mr.subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr
  WHERE LOWER(mr.status) = 'active'                              -- active prescriptions
  GROUP BY patient_id
  HAVING COUNT(DISTINCT mr.medication.codeableConcept.text) >= 7 -- ≥7 unique meds
)
SELECT
  COUNT(DISTINCT a.patient_id) AS total_alive_with_diag_and_7_active_meds
FROM alive        AS a
JOIN diagnosed    AS d USING (patient_id)
JOIN polypharmacy AS p USING (patient_id);