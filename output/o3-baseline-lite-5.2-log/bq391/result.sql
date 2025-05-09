WITH eligible_patients AS (
  -- living patients whose last name starts with “A”
  SELECT
    p.id                                         AS patient_id,
    ANY_VALUE(n.family)                          AS last_name
  FROM `bigquery-public-data.fhir_synthea.patient` AS p
  CROSS JOIN UNNEST(p.name) AS n
  WHERE (p.deceased IS NULL                          -- no deceased block
         OR (p.deceased.boolean IS NULL OR p.deceased.boolean = FALSE))
    AND n.family IS NOT NULL
    AND STARTS_WITH(UPPER(n.family), 'A')
  GROUP BY p.id
),
patient_conditions AS (
  -- one row per patient‑condition pair
  SELECT
    c.subject.patientId                                                    AS patient_id,
    (SELECT cod.code
       FROM UNNEST(c.code.coding) AS cod
       WHERE cod.code IS NOT NULL
       LIMIT 1)                                                            AS condition_code
  FROM `bigquery-public-data.fhir_synthea.condition` AS c
),
single_condition_patients AS (
  -- keep only patients that have exactly one distinct condition
  SELECT
    ep.patient_id,
    MAX(pc.condition_code) AS condition_code
  FROM eligible_patients      AS ep
  JOIN patient_conditions     AS pc
    ON pc.patient_id = ep.patient_id
  GROUP BY ep.patient_id
  HAVING COUNT(DISTINCT pc.condition_code) = 1
),
patient_med_counts AS (
  -- number of DISTINCT active medication codes per (patient, condition)
  SELECT
    scp.patient_id,
    scp.condition_code,
    COUNT(DISTINCT mc.code) AS distinct_active_meds
  FROM single_condition_patients                              AS scp
  JOIN `bigquery-public-data.fhir_synthea.medication_request` AS mr
    ON mr.subject.patientId = scp.patient_id
   AND mr.status = 'active'
  CROSS JOIN UNNEST(mr.medication.codeableConcept.coding) AS mc
  WHERE mc.code IS NOT NULL
  GROUP BY scp.patient_id, scp.condition_code
),
condition_max_meds AS (
  -- best (max) per condition across all patients
  SELECT
    condition_code,
    MAX(distinct_active_meds) AS max_active_meds
  FROM patient_med_counts
  GROUP BY condition_code
)
-- final 8 conditions with highest max_active_meds
SELECT
  condition_code,
  max_active_meds
FROM condition_max_meds
ORDER BY max_active_meds DESC, condition_code
LIMIT 8;