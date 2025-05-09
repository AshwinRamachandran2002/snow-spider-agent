SELECT
  condition_data.condition_name AS Condition_Name,
  condition_data.condition_code AS Condition_Code,
  MAX(medication_data.medication_count) AS Max_Number_of_Different_Meds_Prescribed
FROM `bigquery-public-data.fhir_synthea.patient` AS p
INNER JOIN UNNEST(p.name) AS n
ON TRUE
INNER JOIN (
  SELECT
    c.subject.patientId AS patientId,
    cd.code AS condition_code,
    cd.display AS condition_name
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  INNER JOIN UNNEST(c.code.coding) AS cd
  ON TRUE
) AS condition_data
ON p.id = condition_data.patientId
INNER JOIN (
  SELECT
    mr.subject.patientId AS patientId,
    COUNT(DISTINCT md.code) AS medication_count
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr
  INNER JOIN UNNEST(mr.medication.codeableConcept.coding) AS md
  ON TRUE
  GROUP BY mr.subject.patientId
) AS medication_data
ON p.id = medication_data.patientId
WHERE LOWER(n.family) LIKE 'a%'
  AND (p.deceased IS NULL OR p.deceased.boolean = FALSE)
  AND p.id IN (
    SELECT sub.patientId
    FROM (
      SELECT
        c.subject.patientId AS patientId,
        COUNT(DISTINCT c.id) AS condition_count
      FROM `bigquery-public-data.fhir_synthea.condition` AS c
      GROUP BY c.subject.patientId
    ) AS sub
    WHERE sub.condition_count = 1
  )
GROUP BY Condition_Name, Condition_Code
ORDER BY Max_Number_of_Different_Meds_Prescribed DESC
LIMIT 8;