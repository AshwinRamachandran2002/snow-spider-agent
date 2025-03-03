WITH alive_patients AS (
  SELECT DISTINCT
    p.id AS patient_id
  FROM
    `bigquery-public-data.fhir_synthea.patient` AS p,
    UNNEST(p.name) AS n
  WHERE
    (p.deceased.boolean IS FALSE OR p.deceased.boolean IS NULL)
    AND STARTS_WITH(UPPER(n.family), 'A')
),
patients_with_one_condition AS (
  SELECT
    c.subject.patientId AS patient_id,
    ANY_VALUE(coding.code) AS condition_code,
    ANY_VALUE(coding.display) AS condition_name
  FROM
    `bigquery-public-data.fhir_synthea.condition` AS c
    LEFT JOIN UNNEST(c.code.coding) AS coding
  WHERE
    c.subject.patientId IN (SELECT patient_id FROM alive_patients)
  GROUP BY
    c.subject.patientId
  HAVING
    COUNT(DISTINCT coding.code) = 1
),
patient_medication_counts AS (
  SELECT
    mr.subject.patientId AS patient_id,
    COUNT(DISTINCT med_coding.code) AS medication_count
  FROM
    `bigquery-public-data.fhir_synthea.medication_request` AS mr
    LEFT JOIN UNNEST(mr.medication.codeableConcept.coding) AS med_coding
  WHERE
    mr.subject.patientId IN (SELECT patient_id FROM patients_with_one_condition)
  GROUP BY
    mr.subject.patientId
),
patient_condition_med_counts AS (
  SELECT
    p.patient_id,
    p.condition_code,
    p.condition_name,
    pm.medication_count
  FROM
    patients_with_one_condition AS p
    LEFT JOIN patient_medication_counts AS pm
    ON p.patient_id = pm.patient_id
),
condition_max_med_counts AS (
  SELECT
    condition_name,
    condition_code,
    MAX(medication_count) AS Max_Number_of_Different_Meds_Prescribed
  FROM
    patient_condition_med_counts
  GROUP BY
    condition_name,
    condition_code
)
SELECT
  condition_name AS Condition_Name,
  condition_code AS Condition_Code,
  Max_Number_of_Different_Meds_Prescribed
FROM
  condition_max_med_counts
ORDER BY
  Max_Number_of_Different_Meds_Prescribed DESC
LIMIT 8;