WITH dx AS (     -- Patients with a diagnosis of Diabetes or Hypertension
  SELECT DISTINCT subj.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
  JOIN UNNEST([c.subject])                AS subj
  CROSS JOIN UNNEST(c.code.coding)        AS cc
  WHERE LOWER(c.code.text) LIKE '%diabetes%'
     OR LOWER(c.code.text) LIKE '%hypertension%'
     OR LOWER(cc.display)  LIKE '%diabetes%'
     OR LOWER(cc.display)  LIKE '%hypertension%'
),
rx AS (     -- Patients with ≥7 distinct active medications
  SELECT patient_id
  FROM (
    SELECT
      mr.subject.patientId        AS patient_id,
      COUNT(DISTINCT mc.code)     AS med_cnt
    FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr
    CROSS JOIN UNNEST(mr.medication.codeableConcept.coding) AS mc
    WHERE mr.status = 'active'
    GROUP BY patient_id
  )
  WHERE med_cnt >= 7
),
alive AS (   -- Patients with NO deceased.dateTime recorded in any claim
  SELECT patient.patientId AS patient_id
  FROM `bigquery-public-data.fhir_synthea.claim`
  GROUP BY patient.patientId
  HAVING MAX(JSON_VALUE(TO_JSON_STRING(patient), '$.deceased.dateTime')) IS NULL
)
SELECT
  COUNT(DISTINCT a.patient_id) AS alive_diab_htn_polypharmacy_patient_cnt
FROM alive AS a
JOIN dx ON a.patient_id = dx.patient_id
JOIN rx ON a.patient_id = rx.patient_id;