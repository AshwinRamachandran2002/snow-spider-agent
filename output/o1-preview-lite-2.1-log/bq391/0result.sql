WITH patients_meeting_criteria AS (
  SELECT p.id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient` p
  JOIN UNNEST(p.name) AS n
  WHERE p.deceased.boolean IS NOT TRUE
    AND LOWER(n.family) LIKE 'a%'
    AND (
      SELECT COUNT(*)
      FROM `bigquery-public-data.fhir_synthea.condition` c
      WHERE c.subject.patientId = p.id
    ) = 1
),

patient_medication_counts AS (
  SELECT p.patient_id, COUNT(DISTINCT med_coding.code) AS medication_count
  FROM patients_meeting_criteria p
  LEFT JOIN `bigquery-public-data.fhir_synthea.medication_request` mr
    ON mr.subject.patientId = p.patient_id
  LEFT JOIN UNNEST(mr.medication.codeableConcept.coding) AS med_coding
  GROUP BY p.patient_id
),

patient_conditions AS (
  SELECT p.patient_id, coding.code AS condition_code, coding.display AS condition_name
  FROM patients_meeting_criteria p
  JOIN `bigquery-public-data.fhir_synthea.condition` c
    ON c.subject.patientId = p.patient_id
  JOIN UNNEST(c.code.coding) AS coding
)

SELECT
  pc.condition_name AS Condition_Name,
  pc.condition_code AS Condition_Code,
  MAX(pm.medication_count) AS Max_Number_of_Different_Meds_Prescribed
FROM patient_conditions pc
JOIN patient_medication_counts pm
  ON pc.patient_id = pm.patient_id
GROUP BY pc.condition_name, pc.condition_code
ORDER BY Max_Number_of_Different_Meds_Prescribed DESC
LIMIT 8