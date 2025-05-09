WITH living_patients AS (                       -- living patients whose last name starts with “A”
    SELECT
        p."id"                                                     AS patient_id,
        UPPER( p."name"[0]:"family"::STRING )                      AS last_name
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA."PATIENT" p
    WHERE p."deceased" IS NULL
      AND p."name" IS NOT NULL
      AND UPPER( p."name"[0]:"family"::STRING ) LIKE 'A%'
),
patient_conditions AS (                          -- every condition each patient has
    SELECT
        c."subject":"patientId"::STRING                               AS patient_id,
        c."code":"coding"[0]:"code"::STRING                           AS condition_code,
        COALESCE( c."code":"coding"[0]:"display"::STRING,
                  c."code":"text"::STRING )                           AS condition_name
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA."CONDITION" c
),
single_condition_patients AS (                   -- keep patients having EXACTLY one distinct condition
    SELECT lp.patient_id
    FROM living_patients lp
    JOIN patient_conditions pc
      ON pc.patient_id = lp.patient_id
    GROUP BY lp.patient_id
    HAVING COUNT(DISTINCT pc.condition_code) = 1
),
patient_single_condition AS (                    -- pair each such patient with that sole condition
    SELECT
        pc.patient_id,
        pc.condition_code,
        pc.condition_name
    FROM patient_conditions pc
    JOIN single_condition_patients sp
      ON sp.patient_id = pc.patient_id
),
active_medications AS (                          -- active medication requests
    SELECT
        mr."subject":"patientId"::STRING                                  AS patient_id,
        mr."medication":"codeableConcept":"coding"[0]:"code"::STRING      AS medication_code
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA."MEDICATION_REQUEST" mr
    WHERE UPPER(mr."status") = 'ACTIVE'
),
patient_med_counts AS (                          -- # distinct active meds per patient
    SELECT
        am.patient_id,
        COUNT(DISTINCT am.medication_code)                       AS active_med_cnt
    FROM active_medications am
    GROUP BY am.patient_id
),
condition_max_meds AS (                          -- for each condition, max active-meds count among its pts
    SELECT
        psc.condition_code,
        psc.condition_name,
        MAX( COALESCE(pmc.active_med_cnt, 0) )                    AS max_active_meds
    FROM patient_single_condition psc
    LEFT JOIN patient_med_counts pmc
           ON pmc.patient_id = psc.patient_id
    GROUP BY psc.condition_code,
             psc.condition_name
)
SELECT
    condition_name,
    condition_code
FROM condition_max_meds
ORDER BY max_active_meds DESC NULLS LAST,
         condition_name
LIMIT 8;