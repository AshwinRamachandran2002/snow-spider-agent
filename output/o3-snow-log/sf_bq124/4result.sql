WITH alive_patients AS (   -- patients with no death date recorded
    SELECT 
        "id" AS patient_id
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA.PATIENT
    WHERE "deceased" IS NULL
),

diag_patients AS (         -- patients diagnosed with Diabetes OR Hypertension
    SELECT DISTINCT
        "subject":"patientId"::string AS patient_id
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA.CONDITION
         , LATERAL FLATTEN ( INPUT => "code":"coding" ) c
    WHERE  LOWER(c.value:"display"::string) LIKE '%diabet%'       -- diabetes
        OR LOWER(c.value:"display"::string) LIKE '%hypertension%' -- hypertension
        OR LOWER(c.value:"code"::string)    IN ('e11','i10')      -- common ICD-10 codes
),

med_counts AS (            -- patients with ≥ 7 distinct active medications
    SELECT
        "subject":"patientId"::string           AS patient_id,
        COUNT(DISTINCT mc.value:"code"::string) AS meds_cnt
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA.MEDICATION_REQUEST mr
         , LATERAL FLATTEN ( INPUT => "medication":"codeableConcept":"coding" ) mc
    WHERE LOWER(mr."status") = 'active'
    GROUP BY patient_id
    HAVING meds_cnt >= 7
)

SELECT 
    COUNT(DISTINCT p.patient_id) AS "ALIVE_DIABETES_OR_HTN_WITH_7_ACTIVE_MEDS"
FROM alive_patients  p
JOIN diag_patients   d ON p.patient_id = d.patient_id
JOIN med_counts      m ON p.patient_id = m.patient_id;