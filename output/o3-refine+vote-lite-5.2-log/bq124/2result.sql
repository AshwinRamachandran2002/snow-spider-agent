-- number of living patients with Diabetes or Hypertension diagnosis
-- and at least 7 distinct active medications
WITH alive_patients AS (
  SELECT id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient`
  WHERE (deceased.`boolean` IS NULL OR deceased.`boolean` = FALSE)
    AND deceased.dateTime IS NULL
),
dx_patients AS (
  -- patients diagnosed with diabetes or hypertension
  SELECT DISTINCT subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition`
  WHERE subject.patientId IS NOT NULL
    AND (
      -- match on the free‑text description
      LOWER(code.text) LIKE '%diabetes%'      OR
      LOWER(code.text) LIKE '%hypertension%'  OR
      -- or on any of the coding displays
      EXISTS (
        SELECT 1
        FROM UNNEST(code.coding) c
        WHERE LOWER(c.display) LIKE '%diabetes%'
           OR LOWER(c.display) LIKE '%hypertension%'
      )
    )
),
med_counts AS (
  -- count distinct active medications per patient
  SELECT
    subject.patientId AS patient_id,
    COUNT(DISTINCT COALESCE(
              (SELECT c.code
               FROM UNNEST(medication.codeableConcept.coding) c
               WHERE c.code IS NOT NULL
               LIMIT 1),
              medication.codeableConcept.text
           )) AS distinct_active_meds
  FROM `bigquery-public-data.fhir_synthea.medication_request`
  WHERE status = 'active'           -- only active prescriptions
    AND subject.patientId IS NOT NULL
  GROUP BY patient_id
  HAVING DISTINCT_ACTIVE_MEDS >= 7
),
eligible AS (
  -- patients who meet all three criteria
  SELECT a.patient_id
  FROM alive_patients   a
  JOIN dx_patients      d USING (patient_id)
  JOIN med_counts       m USING (patient_id)
)
SELECT COUNT(*) AS num_individuals
FROM eligible;