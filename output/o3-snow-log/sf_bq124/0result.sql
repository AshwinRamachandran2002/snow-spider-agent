WITH alive_patients AS (
    SELECT 
        "id" AS patient_id
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA.PATIENT
    WHERE "deceased" IS NULL                -- patient has no recorded date of death
), 
  
diab_htn_patients AS (
    SELECT DISTINCT
        "subject":"patientId"::string AS patient_id
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA.CONDITION
    WHERE  LOWER("code":"text"::string) LIKE '%diabetes%' 
        OR LOWER("code":"text"::string) LIKE '%hypertension%'   -- diabetes or hypertension diagnosis
), 
  
active_meds AS (
    SELECT
        "subject":"patientId"::string                                                  AS patient_id,
        "medication":"codeableConcept":"coding"[0]:"code"::string                     AS med_code
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA.MEDICATION_REQUEST
    WHERE LOWER("status") = 'active'                      -- only active medication requests
), 
  
med_counts AS (
    SELECT
        patient_id,
        COUNT(DISTINCT med_code) AS distinct_active_meds
    FROM active_meds
    GROUP BY patient_id
    HAVING COUNT(DISTINCT med_code) >= 7                 -- at least seven distinct meds
), 
  
qualified_patients AS (
    SELECT a.patient_id
    FROM alive_patients      a
    JOIN diab_htn_patients   d ON a.patient_id = d.patient_id
    JOIN med_counts          m ON a.patient_id = m.patient_id
)

SELECT COUNT(DISTINCT patient_id) AS alive_diab_htn_with_7plus_active_meds
FROM qualified_patients;