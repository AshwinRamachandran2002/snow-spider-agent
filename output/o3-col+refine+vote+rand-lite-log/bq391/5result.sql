-- Top-8 conditions (code & display) that give the largest number of
-- distinct active medications for ANY single patient whose official
-- last-name starts with “A” and who has exactly one distinct condition.
WITH patients_A AS (
  SELECT DISTINCT p.id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient` AS p
  CROSS JOIN UNNEST(p.name) AS n
  WHERE n.use = 'official'
    AND STARTS_WITH(n.family , 'A')        -- last name begins with “A”
),
one_condition_patients AS (
  SELECT c.subject.patientId        AS patient_id ,
         ANY_VALUE(cc.code)         AS condition_code ,
         ANY_VALUE(cc.display)      AS condition_display
  FROM   `bigquery-public-data.fhir_synthea.condition` AS c
  CROSS  JOIN UNNEST(c.code.coding) AS cc
  GROUP  BY patient_id
  HAVING COUNT(DISTINCT cc.code) = 1       -- exactly one condition
),
target_patients AS (
  SELECT pa.patient_id ,
         oc.condition_code ,
         oc.condition_display
  FROM   patients_A           AS pa
  JOIN   one_condition_patients AS oc
  USING  (patient_id)
),
active_meds AS (
  SELECT mr.subject.patientId                      AS patient_id ,
         mc.code                                   AS med_code
  FROM   `bigquery-public-data.fhir_synthea.medication_request` AS mr
  CROSS  JOIN UNNEST(mr.medication.codeableConcept.coding) AS mc
  WHERE  mr.status = 'active'                     -- active prescriptions
),
per_patient_counts AS (
  SELECT tp.patient_id ,
         tp.condition_code ,
         tp.condition_display ,
         COUNT(DISTINCT am.med_code) AS med_cnt
  FROM   target_patients AS tp
  LEFT   JOIN active_meds AS am
  ON     am.patient_id = tp.patient_id
  GROUP  BY tp.patient_id , tp.condition_code , tp.condition_display
)
SELECT condition_display ,
       condition_code ,
       MAX(med_cnt) AS max_distinct_active_meds_to_single_patient
FROM   per_patient_counts
GROUP  BY condition_display , condition_code
ORDER  BY max_distinct_active_meds_to_single_patient DESC
LIMIT 8;