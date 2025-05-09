-- number of living patients (no recorded death) who
--  • have a diagnosis of Diabetes OR Hypertension
--  • are currently prescribed ≥ 7 distinct active medications
WITH
-- 1. alive patients
alive AS (
  SELECT id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient`
  WHERE deceased.dateTime IS NULL
        AND (deceased.boolean IS NULL OR deceased.boolean = FALSE)
),

-- 2. patients with Diabetes or Hypertension diagnosis
dx AS (
  SELECT DISTINCT subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition`
  WHERE LOWER(code.text) LIKE '%diabetes%'
        OR LOWER(code.text) LIKE '%hypertens%'
),

-- 3. count of distinct active medications per patient
med_cnt AS (
  SELECT
      subject.patientId AS patient_id,
      COUNT(DISTINCT LOWER(TRIM(medication.codeableConcept.text))) AS med_total
  FROM `bigquery-public-data.fhir_synthea.medication_request`
  WHERE status = 'active'
        AND medication.codeableConcept.text IS NOT NULL
  GROUP BY subject.patientId
  HAVING med_total >= 7
)

-- 4. final count of patients satisfying all three criteria
SELECT COUNT(*) AS num_patients
FROM alive
JOIN dx      USING (patient_id)
JOIN med_cnt USING (patient_id);