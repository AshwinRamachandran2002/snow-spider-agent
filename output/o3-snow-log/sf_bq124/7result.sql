WITH alive_patients AS (
    -- patients with no recorded date of death
    SELECT  "id"                                                    AS patient_id
    FROM    FHIR_SYNTHEA.FHIR_SYNTHEA.PATIENT
    WHERE   "deceased" IS NULL
),
dx_patients AS (
    -- patients diagnosed with Diabetes OR Hypertension
    SELECT  DISTINCT
            "subject":"patientId"::string                           AS patient_id
    FROM    FHIR_SYNTHEA.FHIR_SYNTHEA.CONDITION
    WHERE   REGEXP_LIKE(
                LOWER( "code":"coding"[0]:"display"::string ),
                'diabetes|hypertension'
            )
),
med_patients AS (
    -- patients with ≥ 7 distinct active medications
    SELECT  "subject":"patientId"::string                           AS patient_id,
            COUNT( DISTINCT
                   "medication":"codeableConcept":"coding"[0]:"code"::string
                 )                                                  AS med_cnt
    FROM    FHIR_SYNTHEA.FHIR_SYNTHEA.MEDICATION_REQUEST
    WHERE   LOWER("status") = 'active'
    GROUP BY  patient_id
    HAVING   med_cnt >= 7
)

SELECT  COUNT(*)  AS num_alive_with_dx_and_7plus_active_meds
FROM    alive_patients
JOIN    dx_patients   USING (patient_id)
JOIN    med_patients  USING (patient_id);