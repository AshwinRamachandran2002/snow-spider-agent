WITH living_patients AS (      -- alive patients, grab a last name
  SELECT
    id AS patient_id,
    UPPER(                      -- make comparison case–insensitive
      (SELECT n.family
         FROM UNNEST(name) AS n
        WHERE n.family IS NOT NULL
        LIMIT 1) ) AS last_name
  FROM `bigquery-public-data.fhir_synthea.patient`
  WHERE (deceased.boolean IS NULL OR deceased.boolean = FALSE)
    AND deceased.dateTime IS NULL
),

patients_a AS (                -- living patients whose last name starts with “A”
  SELECT patient_id
  FROM living_patients
  WHERE last_name LIKE 'A%'
),

patient_condition AS (         -- each patient‑condition pair
  SELECT
    cnd.subject.patientId        AS patient_id,
    cd.code                      AS condition_code,
    ANY_VALUE(cd.display)        AS condition_display
  FROM `bigquery-public-data.fhir_synthea.condition`  AS cnd
  CROSS JOIN UNNEST(cnd.code.coding) AS cd
  WHERE cnd.subject.patientId IN (SELECT patient_id FROM patients_a)
        AND cd.code IS NOT NULL
  GROUP BY patient_id, condition_code
),

single_condition_patients AS ( -- keep patients that have exactly one condition
  SELECT patient_id
  FROM patient_condition
  GROUP BY patient_id
  HAVING COUNT(DISTINCT condition_code) = 1
),

eligible_patients AS (         -- eligible patients with their sole condition
  SELECT
    pc.patient_id,
    pc.condition_code,
    pc.condition_display
  FROM patient_condition       AS pc
  JOIN single_condition_patients USING (patient_id)
),

patient_med_counts AS (        -- number of distinct active meds per patient
  SELECT
    mr.subject.patientId                       AS patient_id,
    COUNT(DISTINCT med.code)                   AS active_med_cnt
  FROM `bigquery-public-data.fhir_synthea.medication_request` AS mr
  CROSS JOIN UNNEST(mr.medication.codeableConcept.coding) AS med
  WHERE mr.status = 'active'
    AND mr.subject.patientId IN (SELECT patient_id FROM eligible_patients)
    AND med.code IS NOT NULL
  GROUP BY patient_id
),

condition_max_meds AS (        -- for each condition, best patient score
  SELECT
    ep.condition_code,
    ANY_VALUE(ep.condition_display)            AS condition_display,
    MAX(IFNULL(pmc.active_med_cnt,0))          AS max_active_meds
  FROM eligible_patients        AS ep
  LEFT JOIN patient_med_counts  AS pmc
         ON ep.patient_id = pmc.patient_id
  GROUP BY ep.condition_code
),

top_eight AS (
  SELECT *
  FROM condition_max_meds
  ORDER BY max_active_meds DESC, condition_code
  LIMIT 8
)

SELECT
  condition_display  AS condition,
  condition_code     AS code,
  max_active_meds    AS max_distinct_active_medications
FROM top_eight;