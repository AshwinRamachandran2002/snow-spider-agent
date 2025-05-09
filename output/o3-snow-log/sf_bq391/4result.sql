WITH live_patients AS (   -- living patients whose last name starts with “A”
    SELECT DISTINCT p."id" AS patient_id
    FROM "FHIR_SYNTHEA"."FHIR_SYNTHEA"."PATIENT" p ,
         LATERAL FLATTEN( INPUT => p."name" ) n
    WHERE p."deceased" IS NULL
      AND UPPER( n.value:"family"::string ) LIKE 'A%'
),
patient_conditions AS (   -- every condition per patient
    SELECT
        c."subject":"patientId"::string                        AS patient_id ,
        c."code":"coding"[0]:"code"::string                   AS condition_code
    FROM "FHIR_SYNTHEA"."FHIR_SYNTHEA"."CONDITION" c
    WHERE c."subject":"patientId" IS NOT NULL
),
single_condition_patients AS (   -- keep patients having exactly ONE distinct condition
    SELECT
        pc.patient_id ,
        MIN( pc.condition_code ) AS condition_code            -- the only condition
    FROM patient_conditions pc
    JOIN live_patients lp
          ON lp.patient_id = pc.patient_id
    GROUP BY pc.patient_id
    HAVING COUNT( DISTINCT pc.condition_code ) = 1
),
patient_med_counts AS (   -- number of DISTINCT active meds per patient
    SELECT
        m."subject":"patientId"::string                                               AS patient_id ,
        COUNT( DISTINCT m."medication":"codeableConcept":"coding"[0]:"code"::string ) AS active_med_count
    FROM "FHIR_SYNTHEA"."FHIR_SYNTHEA"."MEDICATION_REQUEST" m
    JOIN single_condition_patients scp
          ON scp.patient_id = m."subject":"patientId"::string
    WHERE LOWER( m."status" ) = 'active'
    GROUP BY m."subject":"patientId"::string
),
cond_max AS (            -- maximum #active-meds any single patient has for each condition
    SELECT
        scp.condition_code ,
        MAX( COALESCE( pmc.active_med_count , 0 ) ) AS max_active_medications
    FROM single_condition_patients scp
    LEFT JOIN patient_med_counts pmc
           ON pmc.patient_id = scp.patient_id
    GROUP BY scp.condition_code
)
SELECT
    condition_code ,
    max_active_medications
FROM cond_max
ORDER BY max_active_medications DESC NULLS LAST , condition_code
LIMIT 8;