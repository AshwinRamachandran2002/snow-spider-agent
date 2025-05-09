-- number of alive patients (no death recorded) who have diabetes OR hypertension
-- and are currently prescribed at least 7 distinct active medications
WITH alive_patients AS (
  SELECT
    id AS patient_id
  FROM
    `bigquery-public-data.fhir_synthea.patient`
  WHERE
    deceased.dateTime IS NULL
    AND (deceased.boolean IS NULL OR deceased.boolean = FALSE)
),
condition_patients AS (
  -- patients that have a condition whose description or coding mentions
  -- diabetes or hypertension
  SELECT DISTINCT
    c.subject.patientId AS patient_id
  FROM
    `bigquery-public-data.fhir_synthea.condition` AS c
  WHERE
    c.subject.patientId IS NOT NULL
    AND (
      -- check plain‑text field
      LOWER(c.code.text) LIKE '%diabetes%'
      OR LOWER(c.code.text) LIKE '%hypertension%'
      -- or any of the codings
      OR EXISTS (
        SELECT 1
        FROM UNNEST(c.code.coding) AS cd
        WHERE
          LOWER(cd.display)    LIKE '%diabetes%'
          OR LOWER(cd.display) LIKE '%hypertension%'
          OR LOWER(cd.code) IN ('e10','e11','i10','i11','44054006','250000')   -- common diabetes / hypertension codes
      )
    )
),
medication_counts AS (
  -- for every patient count how many different active medications are prescribed
  SELECT
    mr.subject.patientId          AS patient_id,
    COUNT(DISTINCT
          COALESCE(
            (SELECT cd.code
             FROM UNNEST(mr.medication.codeableConcept.coding) AS cd
             WHERE cd.code IS NOT NULL
             LIMIT 1),
            mr.medication.codeableConcept.text
          ))                      AS distinct_active_meds
  FROM
    `bigquery-public-data.fhir_synthea.medication_request` AS mr
  WHERE
    mr.status = 'active'                      -- only active prescriptions
    AND mr.subject.patientId IS NOT NULL
  GROUP BY
    patient_id
  HAVING
    distinct_active_meds >= 7                 -- at least seven different meds
),
eligible_patients AS (
  SELECT
    ap.patient_id
  FROM
    alive_patients     AS ap
    JOIN condition_patients  USING (patient_id)
    JOIN medication_counts   USING (patient_id)
)
SELECT
  COUNT(*) AS alive_with_condition_and_7plus_active_meds
FROM
  eligible_patients;