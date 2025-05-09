WITH
-- 1. Alive patients (no recorded date of death)
alive AS (
  SELECT id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient`
  WHERE deceased.dateTime IS NULL
),

-- 2. Patients diagnosed with Diabetes OR Hypertension
dx AS (
  SELECT DISTINCT subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition`
  WHERE
    LOWER(code.text) LIKE '%diabetes%'     OR
    LOWER(code.text) LIKE '%hypertension%' OR
    EXISTS (
      SELECT 1
      FROM UNNEST(code.coding) AS c
      WHERE LOWER(c.display) LIKE '%diabetes%'
         OR LOWER(c.display) LIKE '%hypertension%'
         OR LOWER(c.code)    LIKE '%diabetes%'
         OR LOWER(c.code)    LIKE '%hypertension%'
    )
),

-- 3. Patients with ≥ 7 distinct active medications
meds AS (
  SELECT
    m.subject.patientId                           AS patient_id,
    COUNT(DISTINCT m.medication.codeableConcept.coding[OFFSET(0)].code) AS med_cnt
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS m
  WHERE m.status = 'active'
  GROUP BY patient_id
  HAVING med_cnt >= 7
)

-- 4. Final count of patients meeting ALL criteria
SELECT COUNT(*) AS qualifying_patients
FROM   alive
JOIN   dx   USING (patient_id)
JOIN   meds USING (patient_id);