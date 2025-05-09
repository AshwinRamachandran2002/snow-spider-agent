WITH patients_filtered AS (        -- living pts whose last name starts with “A”
  SELECT DISTINCT p.id AS patient_id
  FROM `bigquery-public-data.fhir_synthea.patient` p
  CROSS JOIN UNNEST(p.name) AS n
  WHERE n.family IS NOT NULL
        AND STARTS_WITH(UPPER(n.family), 'A')
        AND (
              p.deceased IS NULL                                      -- no death struct
              OR (
                   (p.deceased.boolean IS NULL OR p.deceased.boolean = FALSE)
                   AND p.deceased.dateTime IS NULL
                 )
            )
),
single_condition_patients AS (     -- pts having exactly ONE distinct condition
  SELECT pc.patient_id,
         pc.condition_codes[OFFSET(0)] AS condition_code
  FROM (
    SELECT
      c.subject.patientId                      AS patient_id,
      ARRAY_AGG(DISTINCT cc.code)              AS condition_codes
    FROM `bigquery-public-data.fhir_synthea.condition` c
    CROSS JOIN UNNEST(c.code.coding) AS cc
    WHERE c.subject.patientId IS NOT NULL
    GROUP BY patient_id
  ) pc
  WHERE ARRAY_LENGTH(pc.condition_codes) = 1
),
patient_active_meds AS (           -- active meds (RxNorm code) per patient
  SELECT DISTINCT
         mr.subject.patientId                           AS patient_id,
         mc.code                                        AS medication_code
  FROM `bigquery-public-data.fhir_synthea.medication_request` mr
  CROSS JOIN UNNEST(mr.medication.codeableConcept.coding) AS mc
  WHERE mr.status = 'active'
        AND mr.subject.patientId IS NOT NULL
        AND mc.code IS NOT NULL
),
med_counts_per_patient AS (        -- active‑med count for each target patient
  SELECT
    sc.condition_code,
    sc.patient_id,
    COUNT(DISTINCT pm.medication_code) AS med_cnt
  FROM single_condition_patients sc
  JOIN patients_filtered  pf ON pf.patient_id = sc.patient_id
  LEFT JOIN patient_active_meds pm ON pm.patient_id = sc.patient_id
  GROUP BY sc.condition_code, sc.patient_id
),
condition_max_meds AS (            -- per condition: max meds any one pt takes
  SELECT
    condition_code,
    MAX(med_cnt) AS max_active_meds_per_patient
  FROM med_counts_per_patient
  GROUP BY condition_code
)
-- eight conditions with the highest such maximum
SELECT
  condition_code,
  max_active_meds_per_patient
FROM condition_max_meds
ORDER BY max_active_meds_per_patient DESC, condition_code
LIMIT 8;