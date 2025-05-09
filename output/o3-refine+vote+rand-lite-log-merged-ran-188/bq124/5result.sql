WITH alive_patients AS (
  -- Patients without any recorded date of death
  SELECT
    id AS patient_id
  FROM
    `bigquery-public-data.fhir_synthea.patient`
  WHERE
    deceased.dateTime IS NULL
    AND (deceased.boolean IS NULL OR deceased.boolean = FALSE)
),
patients_with_target_dx AS (
  -- Patients who have at least one Condition that is diabetes or hypertension
  SELECT DISTINCT
    c.subject.patientId AS patient_id
  FROM
    `bigquery-public-data.fhir_synthea.condition` AS c,
    UNNEST(c.code.coding) AS dx_code
  WHERE
    LOWER(dx_code.display) LIKE '%diabetes%'
    OR LOWER(dx_code.display) LIKE '%hypertension%'
),
active_medications AS (
  -- Each (patient, medication code) pair for ACTIVE medication requests
  SELECT
    mr.subject.patientId AS patient_id,
    med.code                                AS med_code
  FROM
    `bigquery-public-data.fhir_synthea.medication_request` AS mr,
    UNNEST(mr.medication.codeableConcept.coding) AS med
  WHERE
    mr.status = 'active'
    AND med.code IS NOT NULL
),
patients_with_7_plus_meds AS (
  -- Patients who have at least 7 distinct active medication codes
  SELECT
    patient_id
  FROM
    active_medications
  GROUP BY
    patient_id
  HAVING
    COUNT(DISTINCT med_code) >= 7
),
eligible_patients AS (
  -- Intersection of all three criteria
  SELECT
    a.patient_id
  FROM
    alive_patients             AS a
  JOIN
    patients_with_target_dx    AS d  USING (patient_id)
  JOIN
    patients_with_7_plus_meds  AS m  USING (patient_id)
)
SELECT
  COUNT(*) AS num_patients_alive_with_target_dx_and_7_plus_active_meds
FROM
  eligible_patients;