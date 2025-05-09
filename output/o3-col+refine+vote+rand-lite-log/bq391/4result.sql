/*  Top eight conditions (name & code) that, for at least one patient who
    (1) is “living” (active = TRUE or NULL),
    (2) has a surname starting with “A”, and
    (3) carries exactly ONE distinct condition,
    are treated with the greatest number of DIFFERENT active medications. */

WITH surname_a_patients AS (                       -- “living” surname-A pts
  SELECT DISTINCT p.id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient` AS p
  CROSS JOIN UNNEST(p.name) AS n
  WHERE (p.active IS NULL OR p.active = TRUE)
    AND n.family LIKE 'A%'
),

one_cond_patients AS (                             -- pts w/ exactly 1 cond.
  SELECT
    c.subject.patientId                                   AS patient_id,
    MIN(c.code.coding[OFFSET(0)].code)    AS condition_code,   -- single value
    MIN(c.code.coding[OFFSET(0)].display) AS condition_name
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  JOIN surname_a_patients sap
    ON sap.patient_id = c.subject.patientId
  GROUP BY patient_id
  HAVING COUNT(DISTINCT c.code.coding[OFFSET(0)].code) = 1
),

active_meds_per_patient AS (                        -- distinct ACTIVE meds
  SELECT
    mr.subject.patientId AS patient_id,
    COUNT(DISTINCT mr.medication.codeableConcept.coding[OFFSET(0)].code)
        AS active_med_cnt
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr
  WHERE mr.status = 'active'
    AND mr.subject.patientId IN (SELECT patient_id FROM one_cond_patients)
  GROUP BY patient_id
),

patient_condition_meds AS (                         -- merge cond & med cnt
  SELECT
    ocp.condition_name,
    ocp.condition_code,
    COALESCE(amp.active_med_cnt, 0) AS active_med_cnt
  FROM one_cond_patients      AS ocp
  LEFT JOIN active_meds_per_patient AS amp
    USING (patient_id)
)

SELECT
  condition_name,
  condition_code,
  MAX(active_med_cnt) AS highest_active_med_cnt_for_one_patient
FROM patient_condition_meds
GROUP BY condition_name, condition_code
ORDER BY highest_active_med_cnt_for_one_patient DESC
LIMIT 8;