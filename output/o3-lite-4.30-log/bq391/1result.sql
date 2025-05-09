WITH living_a_patients AS (                                            -- 1. living patients, last‑name starts with “A”
  SELECT DISTINCT p.id AS patient_id
  FROM   `bigquery-public-data.fhir_synthea.patient` AS p
  CROSS  JOIN UNNEST(p.name) AS n
  WHERE  n.family LIKE 'A%'                                     -- last name begins with A
    AND  p.deceased.boolean IS NULL
    AND  p.deceased.dateTime IS NULL
),
one_condition_patients AS (                                           -- 2. those patients that have exactly one condition
  SELECT c.subject.patientId              AS patient_id,
         ANY_VALUE(cc.code)               AS condition_code,
         ANY_VALUE(cc.display)            AS condition_name
  FROM   `bigquery-public-data.fhir_synthea.condition` AS c
  CROSS  JOIN UNNEST(c.code.coding) AS cc
  WHERE  c.subject.patientId IN (SELECT patient_id FROM living_a_patients)
  GROUP  BY patient_id
  HAVING COUNT(DISTINCT c.id) = 1
),
patient_med_counts AS (                                               -- 3. distinct active‑drug count per patient
  SELECT mr.subject.patientId         AS patient_id,
         COUNT(DISTINCT mc.code)      AS active_med_cnt
  FROM   `bigquery-public-data.fhir_synthea.medication_request` AS mr
  CROSS  JOIN UNNEST(mr.medication.codeableConcept.coding) AS mc
  WHERE  mr.status = 'active'
    AND  mr.subject.patientId IN (SELECT patient_id FROM living_a_patients)
  GROUP  BY patient_id
),
condition_max_med AS (                                                -- 4. max active‑drug count per condition
  SELECT oc.condition_code,
         oc.condition_name,
         MAX(pm.active_med_cnt) AS max_active_meds
  FROM   one_condition_patients AS oc
  JOIN   patient_med_counts    AS pm
         ON oc.patient_id = pm.patient_id
  GROUP  BY oc.condition_code, oc.condition_name
)
SELECT condition_name AS condition,
       condition_code AS code
FROM   condition_max_med
ORDER  BY max_active_meds DESC, condition_name
LIMIT 8;