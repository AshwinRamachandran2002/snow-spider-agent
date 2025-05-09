WITH living_patients AS (
  -- Patients without a recorded date of death
  SELECT
    id AS patientId
  FROM
    `bigquery-public-data.fhir_synthea.patient`
  WHERE
    deceased.dateTime IS NULL              -- no death recorded
),
condition_patients AS (
  -- Patients diagnosed with diabetes or hypertension
  SELECT DISTINCT
    subject.patientId
  FROM
    `bigquery-public-data.fhir_synthea.condition`,
    UNNEST(code.coding) AS coding
  WHERE
    LOWER(coding.display) LIKE '%diabet%'
    OR LOWER(coding.display) LIKE '%hypertens%'
),
polypharm_patients AS (
  -- Patients on seven or more distinct active medications
  SELECT
    subject.patientId
  FROM
    `bigquery-public-data.fhir_synthea.medication_request`
  WHERE
    status = 'active'
  GROUP BY
    subject.patientId
  HAVING
    COUNT(
      DISTINCT COALESCE(
        medication.codeableConcept.text,
        medication.codeableConcept.coding[OFFSET(0)].display
      )
    ) >= 7
)
SELECT
  COUNT(*) AS num_alive_diab_or_htn_polypharm_patients
FROM
  living_patients        lp
  JOIN condition_patients cp ON lp.patientId = cp.patientId
  JOIN polypharm_patients pp ON lp.patientId = pp.patientId;