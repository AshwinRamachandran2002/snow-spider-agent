WITH alive AS (  -- patients without a recorded date of death
    SELECT 
        "id" AS patient_id
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA.PATIENT
    WHERE "deceased" IS NULL
), diagnosis AS (  -- patients diagnosed with diabetes or hypertension
    SELECT 
        "subject":"patientId"::string AS patient_id
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA."CONDITION"
    WHERE  LOWER(TO_VARCHAR("code")) LIKE '%diabetes%'
       OR LOWER(TO_VARCHAR("code")) LIKE '%hypertension%'
), meds AS (  -- patients with ≥7 distinct active medications
    SELECT
        "subject":"patientId"::string               AS patient_id,
        COUNT(DISTINCT TO_VARCHAR("medication"))    AS med_cnt
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA.MEDICATION_REQUEST
    WHERE "status" = 'active'
    GROUP BY "subject":"patientId"
    HAVING med_cnt >= 7
)
SELECT 
    COUNT(DISTINCT a.patient_id) AS alive_with_dx_and_7plus_meds
FROM alive      a
JOIN diagnosis  d ON a.patient_id = d.patient_id
JOIN meds       m ON a.patient_id = m.patient_id;