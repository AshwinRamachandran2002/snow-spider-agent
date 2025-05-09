WITH 
-- 1. living patients whose LAST name starts with “A”
PATIENTS_LIVING_A AS (
    SELECT DISTINCT 
           p."id"                                                   AS patient_id
    FROM   FHIR_SYNTHEA.FHIR_SYNTHEA.PATIENT  p ,                   
           LATERAL FLATTEN ( input => p."name" ) n
    WHERE  p."deceased" IS NULL                                    -- living
      AND  n.value:"family" IS NOT NULL
      AND  UPPER( SUBSTR( n.value:"family"::string , 1 , 1 ) ) = 'A'
),   

-- 2. every condition record for those patients
PATIENT_CONDITION AS (
    SELECT
          c."subject":"patientId"::string                           AS patient_id ,
          c."code":"coding"[0]:"code"::string                      AS condition_code ,
          COALESCE( c."code":"text"::string , 
                    c."code":"coding"[0]:"display"::string )       AS condition_text
    FROM  FHIR_SYNTHEA.FHIR_SYNTHEA.CONDITION c
          JOIN PATIENTS_LIVING_A pa
            ON pa.patient_id = c."subject":"patientId"::string
),   

-- 3. keep only patients who have exactly ONE distinct condition
SINGLE_CONDITION_PATIENTS AS (
    SELECT  patient_id ,
            MIN( condition_code ) AS condition_code                -- the single condition
    FROM    PATIENT_CONDITION
    GROUP BY patient_id
    HAVING  COUNT( DISTINCT condition_code ) = 1
),

-- 4. active medication counts per (patient, condition)
PATIENT_MED_CNT AS (    
    SELECT  scp.patient_id ,
            scp.condition_code ,
            COUNT( DISTINCT mr."medication":"codeableConcept":"coding"[0]:"code"::string )  AS med_cnt
    FROM    SINGLE_CONDITION_PATIENTS              scp
            LEFT JOIN FHIR_SYNTHEA.FHIR_SYNTHEA.MEDICATION_REQUEST mr
                   ON mr."subject":"patientId"::string = scp.patient_id
                  AND LOWER( mr."status" ) = 'active'
    GROUP BY scp.patient_id , scp.condition_code
),

-- 5. for each condition, maximum number of active meds any single patient has
COND_MAX_MED AS (
    SELECT  condition_code ,
            MAX( med_cnt )  AS max_med_cnt
    FROM    PATIENT_MED_CNT
    GROUP BY condition_code
),

-- 6. attach a readable text for the condition
COND_WITH_TEXT AS (
    SELECT DISTINCT
           pc.condition_code ,
           pc.condition_text
    FROM   PATIENT_CONDITION pc
           JOIN SINGLE_CONDITION_PATIENTS scp
             ON scp.patient_id = pc.patient_id
)

-- 7. final answer – top 8 conditions
SELECT   cwt.condition_text ,
         cmm.condition_code ,
         cmm.max_med_cnt
FROM     COND_MAX_MED   cmm
         JOIN COND_WITH_TEXT cwt
           ON cwt.condition_code = cmm.condition_code
ORDER BY cmm.max_med_cnt DESC NULLS LAST ,
         cmm.condition_code
LIMIT 8;