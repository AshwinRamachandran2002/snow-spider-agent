WITH alive_patients AS (
    SELECT "id" AS patient_id
    FROM "FHIR_SYNTHEA"."FHIR_SYNTHEA"."PATIENT"
    WHERE "deceased" IS NULL
),
conditions_of_interest AS (
    SELECT DISTINCT "subject"::VARIANT:"patientId"::STRING AS patient_id
    FROM "FHIR_SYNTHEA"."FHIR_SYNTHEA"."CONDITION"
    WHERE "code"::VARIANT:"coding"[0]:"code"::STRING IN ('44054006', '38341003')
),
medications_per_patient AS (
    SELECT "subject"::VARIANT:"patientId"::STRING AS patient_id, COUNT("id") AS medication_count
    FROM "FHIR_SYNTHEA"."FHIR_SYNTHEA"."MEDICATION_REQUEST"
    GROUP BY patient_id
)
SELECT COUNT(DISTINCT a.patient_id) AS "Number_of_patients"
FROM alive_patients a
JOIN conditions_of_interest c ON a.patient_id = c.patient_id
JOIN medications_per_patient m ON a.patient_id = m.patient_id
WHERE m.medication_count >= 7;