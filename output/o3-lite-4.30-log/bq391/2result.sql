WITH living_a_patients AS (
  SELECT DISTINCT p.id
  FROM `bigquery-public-data.fhir_synthea.patient` AS p
  CROSS JOIN UNNEST(p.name) AS n
  WHERE n.family LIKE 'A%'
    AND (p.deceased.boolean IS FALSE OR p.deceased.boolean IS NULL)
),
patient_condition_codes AS (
  SELECT c.subject.patientId AS patient_id,
         cc.code,
         cc.display
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  CROSS JOIN UNNEST(c.code.coding) AS cc
  WHERE c.subject.patientId IN (SELECT id FROM living_a_patients)
),
single_condition_patients AS (
  SELECT patient_id
  FROM patient_condition_codes
  GROUP BY patient_id
  HAVING COUNT(DISTINCT code) = 1
),
patient_active_meds AS (
  SELECT mr.subject.patientId AS patient_id,
         COUNT(DISTINCT mc.code) AS med_cnt
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr
  CROSS JOIN UNNEST(mr.medication.codeableConcept.coding) AS mc
  WHERE mr.status = 'active'
    AND mr.subject.patientId IN (SELECT patient_id FROM single_condition_patients)
    AND mc.code IS NOT NULL
  GROUP BY patient_id
),
condition_max_meds AS (
  SELECT pc.code,
         pc.display AS condition,
         MAX(COALESCE(pm.med_cnt, 0)) AS max_meds
  FROM patient_condition_codes AS pc
  JOIN single_condition_patients AS sp
    ON pc.patient_id = sp.patient_id
  LEFT JOIN patient_active_meds AS pm
    ON pc.patient_id = pm.patient_id
  GROUP BY pc.code, pc.display
)
SELECT condition,
       code
FROM condition_max_meds
ORDER BY max_meds DESC, code
LIMIT 8;