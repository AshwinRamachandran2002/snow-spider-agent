-- Number of living patients who have Diabetes or Hypertension
--   AND have ≥ 7 distinct active medications
WITH alive_patients AS (
  SELECT id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient`
  WHERE deceased IS NULL                     -- no deceased element
     OR deceased.dateTime IS NULL            -- or deceased.dateTime missing
),
dx_patients AS (                             -- Diabetes or Hypertension
  SELECT DISTINCT cnd.subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition` AS cnd
  LEFT JOIN UNNEST(cnd.code.coding) AS cc          -- may be empty
  WHERE cnd.subject.patientId IS NOT NULL
    AND (
          -- text‐based match
          LOWER(cnd.code.text)     LIKE '%diabetes%'  OR
          LOWER(cnd.code.text)     LIKE '%hypertens%' OR
          LOWER(cc.display)        LIKE '%diabetes%'  OR
          LOWER(cc.display)        LIKE '%hypertens%' OR
          -- common SNOMED codes
          cc.code IN ('73211009',  -- Diabetes mellitus
                       '46635009', -- Type 1 DM
                       '44054006', -- Type 2 DM
                       '38341003') -- Hypertensive disorder
        )
),
patient_meds AS (                       -- active MedicationRequests
  SELECT DISTINCT
         mr.subject.patientId AS patient_id,
         mc.code                AS med_code
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr
  JOIN UNNEST(mr.medication.codeableConcept.coding) AS mc
  WHERE LOWER(mr.status) = 'active'
    AND mr.subject.patientId IS NOT NULL
    AND mc.code IS NOT NULL
),
med_counts AS (                         -- patients with ≥ 7 meds
  SELECT patient_id,
         COUNT(DISTINCT med_code) AS med_cnt
  FROM patient_meds
  GROUP BY patient_id
  HAVING med_cnt >= 7
),
eligible_patients AS (                  -- satisfy all three criteria
  SELECT a.patient_id
  FROM   alive_patients  AS a
  JOIN   dx_patients     AS d USING (patient_id)
  JOIN   med_counts      AS m USING (patient_id)
)
SELECT COUNT(*) AS num_patients
FROM   eligible_patients;