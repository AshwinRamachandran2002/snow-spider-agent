WITH living_patients AS (
    SELECT
        p."id"                                                   AS patient_id,
        p."name"[0]:"family"::string                             AS last_name
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA.PATIENT p
    WHERE p."deceased" IS NULL
      AND p."name"[0]:"family"::string ILIKE 'A%'            -- last name begins with A
),
patient_condition_counts AS (                               -- how many different conditions each patient has
    SELECT
        c."subject":"patientId"::string                       AS patient_id,
        COUNT(DISTINCT c."code":"coding"[0]:"code"::string)   AS cond_cnt
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA.CONDITION c
    GROUP BY c."subject":"patientId"::string
),
eligible_patients AS (                                      -- living, last name A, exactly one condition
    SELECT lp.patient_id
    FROM living_patients lp
    JOIN patient_condition_counts pc
      ON pc.patient_id = lp.patient_id
    WHERE pc.cond_cnt = 1
),
patient_condition AS (                                      -- pick that single condition per patient
    SELECT
        c."subject":"patientId"::string                     AS patient_id,
        c."code":"coding"[0]:"code"::string                 AS condition_code,
        c."code":"coding"[0]:"display"::string              AS condition_display,
        ROW_NUMBER() OVER (PARTITION BY c."subject":"patientId"::string ORDER BY c."id") AS rn
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA.CONDITION c
    WHERE c."subject":"patientId"::string IN (SELECT patient_id FROM eligible_patients)
),
unique_patient_condition AS (                               -- keep one row per patient
    SELECT patient_id, condition_code, condition_display
    FROM patient_condition
    WHERE rn = 1
),
patient_active_meds AS (                                    -- distinct active meds per patient
    SELECT
        mr."subject":"patientId"::string                               AS patient_id,
        mr."medication":"codeableConcept":"coding"[0]:"code"::string   AS medication_code
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA.MEDICATION_REQUEST mr
    WHERE mr."status" = 'active'
      AND mr."subject":"patientId"::string IN (SELECT patient_id FROM eligible_patients)
    GROUP BY mr."subject":"patientId"::string,
             mr."medication":"codeableConcept":"coding"[0]:"code"::string
),
med_cnt_per_patient AS (                                   -- count meds for each patient
    SELECT
        p.patient_id,
        COUNT(DISTINCT m.medication_code) AS med_cnt
    FROM unique_patient_condition p
    LEFT JOIN patient_active_meds m
           ON m.patient_id = p.patient_id
    GROUP BY p.patient_id
),
condition_patient_medcnt AS (                              -- attach med count to condition
    SELECT
        u.condition_code,
        u.condition_display,
        u.patient_id,
        COALESCE(mp.med_cnt,0) AS med_cnt
    FROM unique_patient_condition u
    LEFT JOIN med_cnt_per_patient mp
           ON mp.patient_id = u.patient_id
),
condition_max AS (                                         -- max meds any single patient has per condition
    SELECT
        condition_code,
        condition_display,
        MAX(med_cnt) AS max_active_meds
    FROM condition_patient_medcnt
    GROUP BY condition_code, condition_display
),
ranked AS (                                                -- rank and keep top 8
    SELECT
        condition_code,
        condition_display,
        max_active_meds,
        ROW_NUMBER() OVER (ORDER BY max_active_meds DESC NULLS LAST, condition_code) AS rn
    FROM condition_max
)
SELECT
    condition_display  AS "CONDITION",
    condition_code     AS "CONDITION_CODE",
    max_active_meds    AS "MAX_ACTIVE_MEDICATIONS"
FROM ranked
WHERE rn <= 8
ORDER BY max_active_meds DESC NULLS LAST, condition_display;