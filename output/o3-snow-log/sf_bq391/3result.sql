WITH eligible_patients AS (
    SELECT
        "id"                                            AS patient_id,
        "name"[0]:"family"::string                      AS last_name
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA."PATIENT"
    WHERE "deceased" IS NULL
      AND UPPER("name"[0]:"family"::string) LIKE 'A%'
),
patient_conditions AS (
    SELECT
        c."subject":"patientId"::string                 AS patient_id,
        c."code":"coding"[0]:"code"::string             AS condition_code,
        c."code":"coding"[0]:"display"::string          AS condition_display
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA."CONDITION" c
),
patients_one_condition AS (
    SELECT
        pc.patient_id,
        MIN(pc.condition_code)      AS condition_code,     -- same for that patient
        MIN(pc.condition_display)   AS condition_display
    FROM patient_conditions pc
    GROUP BY pc.patient_id
    HAVING COUNT(DISTINCT pc.condition_code) = 1          -- exactly one distinct condition
),
eligible_patients_with_condition AS (
    SELECT
        poc.patient_id,
        poc.condition_code,
        poc.condition_display
    FROM patients_one_condition poc
    JOIN eligible_patients ep
      ON ep.patient_id = poc.patient_id                   -- living & last-name “A”
),
patient_active_med_count AS (
    SELECT
        mr."subject":"patientId"::string                                            AS patient_id,
        COUNT(DISTINCT mr."medication":"codeableConcept":"coding"[0]:"code"::string) AS active_med_cnt
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA."MEDICATION_REQUEST" mr
    WHERE mr."status" = 'active'                                                    -- active meds only
    GROUP BY mr."subject":"patientId"::string
),
condition_best_patient AS (
    SELECT
        epwc.condition_code,
        epwc.condition_display,
        MAX(COALESCE(pam.active_med_cnt,0)) AS max_active_med_cnt                  -- “any single patient”
    FROM eligible_patients_with_condition epwc
    LEFT JOIN patient_active_med_count pam
           ON epwc.patient_id = pam.patient_id
    GROUP BY epwc.condition_code, epwc.condition_display
)
SELECT
    condition_display               AS "CONDITION",
    condition_code                  AS "CODE",
    max_active_med_cnt              AS "MAX_ACTIVE_MEDICATION_COUNT"
FROM condition_best_patient
ORDER BY max_active_med_cnt DESC NULLS LAST, condition_display
LIMIT 8;