SELECT COUNT(DISTINCT p.id) AS Number_of_patients
FROM `bigquery-public-data.fhir_synthea.patient` p
JOIN `bigquery-public-data.fhir_synthea.condition` c
  ON p.id = c.subject.patientId
JOIN (
  SELECT subject.patientId
  FROM `bigquery-public-data.fhir_synthea.medication_request`
  GROUP BY subject.patientId
  HAVING COUNT(*) >= 7
) m
  ON p.id = m.patientId
WHERE (p.deceased.boolean IS NULL OR p.deceased.boolean = FALSE)
  AND c.clinicalStatus = 'active'
  AND (LOWER(c.code.text) LIKE '%diabetes%' OR LOWER(c.code.text) LIKE '%hypertension%')