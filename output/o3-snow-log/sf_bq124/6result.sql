WITH alive_patients AS (                              -- patients who are still alive
    SELECT 
        "id" AS patient_id
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA.PATIENT
    WHERE "deceased" IS NULL
),

diagnosis_patients AS (                               -- diabetes OR hypertension diagnosis
    SELECT DISTINCT
        "subject":"patientId"::STRING AS patient_id
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA.CONDITION
    WHERE   LOWER("code"::STRING) LIKE '%diabetes%' 
        OR  LOWER("code"::STRING) LIKE '%hypertension%'
),

med_counts AS (                                       -- ≥ 7 distinct active meds
    SELECT
        "subject":"patientId"::STRING                                    AS patient_id,
        COUNT(DISTINCT "medication":"codeableConcept":"text"::STRING)    AS med_cnt
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA.MEDICATION_REQUEST
    WHERE "status" = 'active'
    GROUP BY 1
    HAVING med_cnt >= 7
)

SELECT COUNT(*) AS num_patients
FROM   alive_patients
JOIN   diagnosis_patients USING (patient_id)
JOIN   med_counts        USING (patient_id);