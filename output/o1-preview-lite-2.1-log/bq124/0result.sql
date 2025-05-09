SELECT COUNT(*) AS Number_of_patients
FROM (
  SELECT p.id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient` AS p
  JOIN `bigquery-public-data.fhir_synthea.condition` AS c
    ON p.id = c.subject.patientId
  JOIN `bigquery-public-data.fhir_synthea.medication_request` AS m
    ON p.id = m.subject.patientId
  WHERE p.deceased.boolean IS NOT TRUE
    AND c.clinicalStatus = 'active'
    AND (
      EXISTS (
        SELECT 1
        FROM UNNEST(c.code.coding) AS coding
        WHERE LOWER(coding.display) LIKE '%diabetes%'
        OR LOWER(coding.display) LIKE '%hypertension%'
      )
    )
    AND m.status = 'active'
  GROUP BY p.id
  HAVING COUNT(DISTINCT m.id) >= 7
)