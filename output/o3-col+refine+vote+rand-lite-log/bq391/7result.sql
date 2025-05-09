-- Among living “A%”-surname patients who have exactly one Condition,
-- find the 8 Conditions whose single-patient maximum of DISTINCT active
-- medications is highest, and return their codes and display names.
WITH living_a_patients AS (         -- 1) Alive & surname starts with “A”
  SELECT DISTINCT p.id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient` AS p
  JOIN UNNEST(p.name) AS n
  WHERE n.family LIKE 'A%'
    AND (p.active IS TRUE OR p.active IS NULL)
),
single_condition_pts AS (          -- 2) keep only pts with exactly 1 Condition
  SELECT lap.patient_id,
         ANY_VALUE(cd.code)    AS condition_code,
         ANY_VALUE(cd.display) AS condition_text
  FROM living_a_patients        AS lap
  JOIN `bigquery-public-data.fhir_synthea.condition` AS c
    ON c.subject.patientId = lap.patient_id
  JOIN UNNEST(c.code.coding) AS cd
  GROUP BY lap.patient_id
  HAVING COUNT(DISTINCT c.id) = 1
),
patient_med_counts AS (           -- 3) count DISTINCT active meds per patient
  SELECT scp.patient_id,
         scp.condition_code,
         scp.condition_text,
         COUNT(DISTINCT med.code) AS num_active_meds
  FROM single_condition_pts                          AS scp
  JOIN `bigquery-public-data.fhir_synthea.medication_request` AS mr
    ON mr.subject.patientId = scp.patient_id
  JOIN UNNEST(mr.medication.codeableConcept.coding)  AS med
  WHERE mr.status = 'active'
  GROUP BY scp.patient_id, scp.condition_code, scp.condition_text
),
condition_max AS (                -- 4) best (max) patient-med count per Condition
  SELECT condition_code,
         condition_text,
         MAX(num_active_meds) AS max_distinct_active_meds
  FROM patient_med_counts
  GROUP BY condition_code, condition_text
)
SELECT condition_code,
       condition_text,
       max_distinct_active_meds
FROM condition_max
ORDER BY max_distinct_active_meds DESC, condition_code
LIMIT 8;