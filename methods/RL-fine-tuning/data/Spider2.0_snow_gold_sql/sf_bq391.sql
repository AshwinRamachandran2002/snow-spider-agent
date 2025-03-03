WITH patient_names AS (
    SELECT 
        p."id" AS patient_id,
        n.value:"family"::STRING AS last_name
    FROM "FHIR_SYNTHEA"."FHIR_SYNTHEA"."PATIENT" p,
         LATERAL FLATTEN(input => p."name") n
    WHERE
        (p."deceased" IS NULL OR p."deceased"::STRING = 'false')
        AND n.value:"family"::STRING ILIKE 'A%'
),
patients_with_one_condition AS (
    SELECT
        c."subject"::VARIANT:"patientId"::STRING AS patient_id,
        COUNT(DISTINCT c."id") AS condition_count
    FROM "FHIR_SYNTHEA"."FHIR_SYNTHEA"."CONDITION" c
    GROUP BY c."subject"::VARIANT:"patientId"::STRING
    HAVING COUNT(DISTINCT c."id") = 1
),
patients_with_lastname_A_and_one_condition AS (
    SELECT pn.patient_id
    FROM patient_names pn
    INNER JOIN patients_with_one_condition pwoc ON pn.patient_id = pwoc.patient_id
),
patient_conditions AS (
    SELECT
        c."subject"::VARIANT:"patientId"::STRING AS patient_id,
        c."code"::VARIANT:"coding"[0]:"code"::STRING AS condition_code
    FROM "FHIR_SYNTHEA"."FHIR_SYNTHEA"."CONDITION" c
    WHERE c."subject"::VARIANT:"patientId"::STRING IN (SELECT patient_id FROM patients_with_lastname_A_and_one_condition)
),
active_medications_per_patient AS (
    SELECT
        m."subject"::VARIANT:"patientId"::STRING AS patient_id,
        COUNT(DISTINCT m."medication"::VARIANT:"codeableConcept":"coding"[0]:"code"::STRING) AS active_med_count
    FROM "FHIR_SYNTHEA"."FHIR_SYNTHEA"."MEDICATION_REQUEST" m
    WHERE m."status" = 'active'
        AND m."subject"::VARIANT:"patientId"::STRING IN (SELECT patient_id FROM patients_with_lastname_A_and_one_condition)
    GROUP BY m."subject"::VARIANT:"patientId"::STRING
),
patient_conditions_medications AS (
    SELECT
        pc.condition_code,
        a.active_med_count
    FROM patient_conditions pc
    JOIN active_medications_per_patient a ON pc.patient_id = a.patient_id
)
SELECT
    pcm.condition_code,
    MAX(pcm.active_med_count) AS number_of_different_active_medications
FROM patient_conditions_medications pcm
GROUP BY pcm.condition_code
ORDER BY number_of_different_active_medications DESC NULLS LAST
LIMIT 8;