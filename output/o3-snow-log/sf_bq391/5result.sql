WITH living_patients AS (   -- alive and last-name starts with “A”
    SELECT "id"                                                        AS patient_id
    FROM   FHIR_SYNTHEA.FHIR_SYNTHEA.PATIENT
    WHERE  "deceased" IS NULL
      AND  UPPER("name"[0]:"family"::string) LIKE 'A%'
),
patient_conditions AS (     -- conditions of those patients
    SELECT c."subject":"patientId"::string                              AS patient_id ,
           c."code":"coding"[0]:"code"::string                          AS condition_code
    FROM   FHIR_SYNTHEA.FHIR_SYNTHEA.CONDITION  c
    WHERE  c."subject":"patientId"::string IN (SELECT patient_id FROM living_patients)
),
single_condition_patients AS (  -- keep patients with exactly one distinct condition
    SELECT   patient_id ,
             MAX(condition_code) AS condition_code   -- only one per patient by definition
    FROM     patient_conditions
    GROUP BY patient_id
    HAVING   COUNT(*) = 1
),
patient_active_med_cnt AS (      -- #distinct active meds per such patient
    SELECT mr."subject":"patientId"::string                               AS patient_id ,
           COUNT(DISTINCT mr."medication":"codeableConcept":"coding"[0]:"code"::string) 
                AS num_active_meds
    FROM   FHIR_SYNTHEA.FHIR_SYNTHEA.MEDICATION_REQUEST mr
    WHERE  mr."status" = 'active'
      AND  mr."subject":"patientId"::string IN (SELECT patient_id FROM single_condition_patients)
    GROUP BY mr."subject":"patientId"::string
),
condition_med_stats AS (       -- tie each condition to that patient’s med count
    SELECT sc.condition_code ,
           pm.num_active_meds
    FROM   single_condition_patients sc
    JOIN   patient_active_med_cnt pm
           ON sc.patient_id = pm.patient_id
)
SELECT   condition_code ,
         num_active_meds
FROM     condition_med_stats
ORDER BY num_active_meds DESC NULLS LAST
FETCH FIRST 8 ROWS ONLY;