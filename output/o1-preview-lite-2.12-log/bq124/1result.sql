SELECT COUNT(DISTINCT p.id) AS number_of_patients
FROM `bigquery-public-data.fhir_synthea.patient` AS p
JOIN (
  SELECT DISTINCT subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  JOIN UNNEST(c.code.coding) AS coding
  WHERE coding.code IN ('44054006', '38341003')
) AS cond
ON p.id = cond.patient_id
JOIN (
  SELECT subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.medication_request`
  WHERE status = 'active'
  GROUP BY subject.patientId
  HAVING COUNT(DISTINCT id) >= 7
) AS med
ON p.id = med.patient_id
WHERE p.deceased.dateTime IS NULL;