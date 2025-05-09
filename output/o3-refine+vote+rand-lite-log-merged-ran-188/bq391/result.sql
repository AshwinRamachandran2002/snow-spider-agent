WITH living_patients_with_lastname_a AS (
  -- living patients whose last name starts with "A"
  SELECT DISTINCT
         p.id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient` p
  LEFT JOIN UNNEST(p.name) AS n
  WHERE (p.deceased.boolean IS NULL AND p.deceased.dateTime IS NULL)
    AND n.family IS NOT NULL
    AND UPPER(SUBSTR(n.family, 1, 1)) = 'A'
),
patient_single_condition AS (
  -- keep only patients that have exactly one DISTINCT condition
  SELECT
        c.subject.patientId      AS patient_id,
        MIN(cc.code)            AS condition_code,      -- safe since exactly one
        MIN(cc.display)         AS condition_display
  FROM `bigquery-public-data.fhir_synthea.condition` c
  JOIN living_patients_with_lastname_a AS lp
       ON lp.patient_id = c.subject.patientId
  LEFT JOIN UNNEST(c.code.coding) AS cc
  GROUP BY patient_id
  HAVING COUNT(DISTINCT cc.code) = 1            -- exactly one distinct condition
),
patient_active_med_counts AS (
  -- count DISTINCT active medication codes per patient
  SELECT
        p.patient_id,
        COUNT(DISTINCT mc.code) AS active_med_cnt
  FROM patient_single_condition        AS p
  LEFT JOIN `bigquery-public-data.fhir_synthea.medication_request` mr
         ON mr.subject.patientId = p.patient_id
        AND mr.status = 'active'
  LEFT JOIN UNNEST(mr.medication.codeableConcept.coding) AS mc
  GROUP BY p.patient_id
),
condition_max_active_meds AS (
  -- for each condition, find the highest number of active meds any one patient has
  SELECT
        p.condition_code,
        p.condition_display,
        MAX(m.active_med_cnt) AS max_patient_active_meds
  FROM patient_single_condition   AS p
  JOIN patient_active_med_counts  AS m
    ON m.patient_id = p.patient_id
  GROUP BY p.condition_code, p.condition_display
)
SELECT
      condition_code,
      condition_display,
      max_patient_active_meds
FROM condition_max_active_meds
ORDER BY max_patient_active_meds DESC, condition_code
LIMIT 8;