/*  Eight conditions whose single “A-surname”, living patient
    has the highest count of distinct ACTIVE medications          */

WITH living_a_patients AS (      -- active = TRUE or NULL & surname starts with “A”
  SELECT DISTINCT p.id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient` AS p
  JOIN UNNEST(p.name) AS n
  WHERE n.use = 'official'
    AND STARTS_WITH(UPPER(n.family), 'A')
    AND (p.active IS TRUE OR p.active IS NULL)
),
single_condition_patients AS (   -- keep only pts with exactly ONE distinct condition
  SELECT c.subject.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  JOIN living_a_patients lap
    ON lap.patient_id = c.subject.patientId
  GROUP BY patient_id
  HAVING COUNT(DISTINCT c.code.coding[OFFSET(0)].code) = 1
),
patient_single_condition AS (    -- attach that lone condition’s code & text
  SELECT DISTINCT
         c.subject.patientId           AS patient_id,
         c.code.coding[OFFSET(0)].code AS condition_code,
         c.code.text                   AS condition_text
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  JOIN single_condition_patients scp
    ON scp.patient_id = c.subject.patientId
),
patient_active_med_cnt AS (      -- count each patient’s DISTINCT active medications
  SELECT
    mr.subject.patientId AS patient_id,
    COUNT(DISTINCT mr.medication.codeableConcept.coding[OFFSET(0)].code) AS active_med_cnt
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr
  WHERE LOWER(mr.status) = 'active'
  GROUP BY patient_id
)
SELECT
  psc.condition_code,
  psc.condition_text,
  MAX(pam.active_med_cnt) AS max_active_meds_for_any_patient
FROM patient_single_condition      AS psc
JOIN patient_active_med_cnt        AS pam
  ON psc.patient_id = pam.patient_id
GROUP BY
  psc.condition_code,
  psc.condition_text
ORDER BY
  max_active_meds_for_any_patient DESC
LIMIT 8;