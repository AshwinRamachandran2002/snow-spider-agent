WITH living_A_patients AS (   -- living patients whose official last name starts with “A”
  SELECT DISTINCT p.id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient` p
  LEFT JOIN UNNEST(p.name) AS n
  WHERE p.deceased IS NULL
    AND n.use = 'official'
    AND n.family LIKE 'A%'
),
one_condition_patients AS (   -- keep only those patients that have exactly ONE distinct condition
  SELECT
    c.subject.patientId                        AS patient_id,
    c.code.coding[OFFSET(0)].code             AS cond_code,
    c.code.text                                AS cond_text
  FROM `bigquery-public-data.fhir_synthea.condition` c
  JOIN living_A_patients lap
    ON lap.patient_id = c.subject.patientId
),
single_cond_patients AS (     -- filter to patients with exactly one condition
  SELECT
    patient_id,
    ANY_VALUE(cond_code) AS cond_code,
    ANY_VALUE(cond_text) AS cond_text
  FROM one_condition_patients
  GROUP BY patient_id
  HAVING COUNT(*) = 1
),
active_med_counts AS (        -- count DISTINCT active meds per qualifying patient
  SELECT
    mr.subject.patientId AS patient_id,
    COUNT(
      DISTINCT mr.medication.codeableConcept.coding[OFFSET(0)].code
    )                        AS med_cnt
  FROM `bigquery-public-data.fhir_synthea.medication_request` mr
  JOIN single_cond_patients scp
    ON scp.patient_id = mr.subject.patientId
  WHERE mr.status = 'active'
  GROUP BY patient_id
),
condition_max_med AS (        -- per condition, keep the MAX active‑med count of any patient
  SELECT
    scp.cond_code,
    scp.cond_text,
    MAX(COALESCE(amc.med_cnt,0)) AS max_active_meds
  FROM single_cond_patients scp
  LEFT JOIN active_med_counts amc
    ON amc.patient_id = scp.patient_id
  GROUP BY scp.cond_code, scp.cond_text
)
SELECT
  cond_code,
  cond_text,
  max_active_meds
FROM condition_max_med
ORDER BY max_active_meds DESC, cond_code
LIMIT 8;