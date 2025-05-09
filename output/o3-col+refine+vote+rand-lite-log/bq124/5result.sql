WITH diabetic_or_htn_patients AS (
  -- Patients whose claims reference a Condition containing “diabetes” or “hypertension”
  SELECT DISTINCT
    c.patient.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.claim` AS c
  CROSS JOIN UNNEST(c.diagnosis) AS d
  WHERE d.diagnosis.reference.conditionId IN (
        SELECT id
        FROM `bigquery-public-data.fhir_synthea.condition` AS cond
        CROSS JOIN UNNEST(cond.code.coding) AS cd
        WHERE LOWER(cd.display) LIKE '%diabetes%'
           OR LOWER(cd.display) LIKE '%hypertension%'
  )
),
polypharmacy_patients AS (
  -- Patients with ≥7 distinct active medications
  SELECT
    mr.subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr
  WHERE mr.status = 'active'
  GROUP BY patient_id
  HAVING COUNT(DISTINCT mr.medication.codeableConcept.text) >= 7
),
alive_patients AS (
  -- Patients who have no recorded date of death
  SELECT id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient`
  WHERE deceased.dateTime IS NULL
)

SELECT
  COUNT(DISTINCT a.patient_id) AS alive_diab_htn_poly_count
FROM alive_patients            AS a
JOIN diabetic_or_htn_patients  AS d USING (patient_id)
JOIN polypharmacy_patients     AS p USING (patient_id);