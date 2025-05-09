WITH alive_patients AS (   -- patients without a recorded death date
    SELECT 
        "id" AS patient_id
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA."PATIENT"
    WHERE "deceased" IS NULL                -- completely absent
       OR "deceased":"dateTime" IS NULL     -- present but no dateTime element
), 

dx_patients AS (          -- patients diagnosed with Diabetes OR Hypertension
    SELECT DISTINCT 
        "subject":"patientId"::string AS patient_id
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA."CONDITION"
    WHERE  LOWER("code"::string) LIKE '%diabetes%' 
        OR LOWER("code"::string) LIKE '%hypertension%'
), 

med_counts AS (           -- patients with ≥ 7 distinct ACTIVE medications
    SELECT 
        "subject":"patientId"::string AS patient_id,
        COUNT( DISTINCT "medication"::string ) AS med_cnt
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA."MEDICATION_REQUEST"
    WHERE LOWER("status") = 'active'
    GROUP BY patient_id
    HAVING med_cnt >= 7
), 

eligible_patients AS (    -- intersection of all three criteria
    SELECT a.patient_id
    FROM   alive_patients a
    JOIN   dx_patients   d ON d.patient_id = a.patient_id
    JOIN   med_counts    m ON m.patient_id = a.patient_id
)

SELECT COUNT(*) AS num_alive_diab_or_htn_with_7plus_active_meds
FROM   eligible_patients;