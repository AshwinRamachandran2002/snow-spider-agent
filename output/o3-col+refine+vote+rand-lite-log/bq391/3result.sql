/*  Eight conditions (code & name) seen in patients whose last names start with
    “A” and who have exactly ONE distinct condition, ranked by the greatest
    number of DIFFERENT active medications held by ANY single patient.
*/
WITH
-- 1.  Patients whose last name begins with “A”.
--     Many rows have NULL in “active”; treat NULL as “still living / not known
--     to be deceased” so keep TRUE or NULL.
patients_a AS (
  SELECT p.id AS patient_id
  FROM   `bigquery-public-data.fhir_synthea.patient` AS p
  JOIN   UNNEST(p.name) AS n
  WHERE  (p.active IS TRUE OR p.active IS NULL)
    AND  UPPER(n.family) LIKE 'A%'
),

-- 2.  Patients (from step-1) who have EXACTLY ONE distinct condition.
one_condition_patients AS (
  SELECT c.subject.patientId AS patient_id
  FROM   `bigquery-public-data.fhir_synthea.condition` AS c
  WHERE  c.subject.patientId IN (SELECT patient_id FROM patients_a)
  GROUP BY patient_id
  HAVING COUNT(DISTINCT c.id) = 1
),

-- 3.  That single condition’s code & display text for each qualified patient.
patient_conditions AS (
  SELECT
    c.subject.patientId AS patient_id,
    cod.code            AS condition_code,
    cod.display         AS condition_display
  FROM   `bigquery-public-data.fhir_synthea.condition` AS c
  JOIN   one_condition_patients AS oc
         ON oc.patient_id = c.subject.patientId
  CROSS  JOIN UNNEST(c.code.coding) AS cod
),

-- 4.  ACTIVE medication requests for those patients.
active_meds AS (
  SELECT
    mr.subject.patientId AS patient_id,
    med.code             AS medication_code
  FROM   `bigquery-public-data.fhir_synthea.medication_request` AS mr
  CROSS  JOIN UNNEST(mr.medication.codeableConcept.coding) AS med
  WHERE  mr.status = 'active'
    AND  mr.subject.patientId IN (SELECT patient_id FROM one_condition_patients)
),

-- 5.  How many DISTINCT active meds each patient has.
med_counts AS (
  SELECT
    patient_id,
    COUNT(DISTINCT medication_code) AS active_med_cnt
  FROM active_meds
  GROUP BY patient_id
),

-- 6.  For every condition, the MAX #active-meds found in ANY single patient.
condition_max_meds AS (
  SELECT
    pc.condition_code,
    pc.condition_display,
    MAX(COALESCE(mc.active_med_cnt,0)) AS max_active_meds_any_patient
  FROM   patient_conditions AS pc
  LEFT   JOIN med_counts AS mc
         ON mc.patient_id = pc.patient_id
  GROUP BY pc.condition_code, pc.condition_display
)

-- 7.  Top eight conditions by that maximum.
SELECT
  condition_display AS condition_name,
  condition_code,
  max_active_meds_any_patient
FROM   condition_max_meds
ORDER  BY max_active_meds_any_patient DESC
LIMIT 8;