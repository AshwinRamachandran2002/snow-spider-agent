-- number of living patients who have Diabetes or Hypertension
-- and at least 7 distinct active medications
WITH alive_patients AS (
  SELECT id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient`
  WHERE deceased IS NULL                                  -- no deceased element
     OR (deceased.dateTime IS NULL                       -- or element present but not populated
         AND (deceased.boolean IS NULL OR deceased.boolean = FALSE))
),
diag_patients AS (
  -- patients with a diabetes or hypertension diagnosis
  SELECT DISTINCT c.subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition`  c
  LEFT JOIN UNNEST(IFNULL(c.code.coding, [])) AS cd      -- explode codings; skip if null
  WHERE
        /* look for key words in either coding.display or code.text */
        LOWER(COALESCE(cd.display, '')) LIKE '%diabetes%'
     OR LOWER(COALESCE(cd.display, '')) LIKE '%hypertension%'
     OR LOWER(COALESCE(c.code.text ,'')) LIKE '%diabetes%'
     OR LOWER(COALESCE(c.code.text ,'')) LIKE '%hypertension%'
),
med_counts AS (
  -- count distinct active medication codes per patient
  SELECT
      mr.subject.patientId            AS patient_id,
      COUNT(DISTINCT mc.code)         AS active_med_cnt
  FROM `bigquery-public-data.fhir_synthea.medication_request` mr
  LEFT JOIN UNNEST(IFNULL(mr.medication.codeableConcept.coding, [])) AS mc
  WHERE mr.status = 'active'
  GROUP BY patient_id
)
SELECT COUNT(*) AS patients_alive_with_dx_and_7plus_active_meds
FROM alive_patients ap
JOIN diag_patients  dp  USING (patient_id)
JOIN med_counts     mc  USING (patient_id)
WHERE mc.active_med_cnt >= 7;