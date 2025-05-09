WITH alive_patients AS (
    SELECT p."id" AS "patient_id"
    FROM "FHIR_SYNTHEA"."FHIR_SYNTHEA"."PATIENT" p
    WHERE p."deceased" IS NULL
),
patients_with_condition AS (
    SELECT DISTINCT c."subject"['patientId']::STRING AS "patient_id"
    FROM "FHIR_SYNTHEA"."FHIR_SYNTHEA"."CONDITION" c
    WHERE LOWER(c."code"['coding'][0]['display']::STRING) LIKE '%diabetes%'
       OR LOWER(c."code"['coding'][0]['display']::STRING) LIKE '%hypertension%'
),
patients_with_medications AS (
    SELECT m."subject"['patientId']::STRING AS "patient_id",
           COUNT(DISTINCT m."medication"['codeableConcept']['coding'][0]['code']::STRING) AS "medication_count"
    FROM "FHIR_SYNTHEA"."FHIR_SYNTHEA"."MEDICATION_REQUEST" m
    WHERE m."status" = 'active'
    GROUP BY m."subject"['patientId']::STRING
    HAVING COUNT(DISTINCT m."medication"['codeableConcept']['coding'][0]['code']::STRING) >= 7
)
SELECT COUNT(*) AS "Number_of_patients"
FROM alive_patients p
JOIN patients_with_condition c ON p."patient_id" = c."patient_id"
JOIN patients_with_medications m ON p."patient_id" = m."patient_id";