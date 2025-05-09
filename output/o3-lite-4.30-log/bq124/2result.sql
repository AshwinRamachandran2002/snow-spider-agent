SELECT
  'alive_diabetes_or_hypertension_with_7plus_active_medications' AS criteria,
  COUNT(*) AS count
FROM (
  -- Alive patients with Diabetes or Hypertension diagnosis
  SELECT DISTINCT
    p.id AS patient_id
  FROM
    `bigquery-public-data.fhir_synthea.patient` AS p
  JOIN
    `bigquery-public-data.fhir_synthea.condition` AS c
  ON
    p.id = c.subject.patientId
  LEFT JOIN
    UNNEST(c.code.coding) AS cod
  WHERE
    p.deceased.dateTime IS NULL
    AND (
      LOWER(c.code.text) LIKE '%diabetes%' OR
      LOWER(c.code.text) LIKE '%hypertension%' OR
      LOWER(cod.display) LIKE '%diabetes%' OR
      LOWER(cod.display) LIKE '%hypertension%'
    )
) AS dx
JOIN (
  -- Patients with at least 7 distinct active medications
  SELECT
    mr.subject.patientId AS patient_id
  FROM
    `bigquery-public-data.fhir_synthea.medication_request` AS mr
  CROSS JOIN
    UNNEST(mr.medication.codeableConcept.coding) AS med
  WHERE
    mr.status = 'active'
  GROUP BY
    patient_id
  HAVING
    COUNT(DISTINCT med.code) >= 7
) AS meds
ON
  dx.patient_id = meds.patient_id;