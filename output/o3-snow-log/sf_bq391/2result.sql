WITH living_patients AS (      -- living patients whose last name starts with “A”
    SELECT  DISTINCT p."id" AS patient_id
    FROM    FHIR_SYNTHEA.FHIR_SYNTHEA.PATIENT  p,
            LATERAL FLATTEN ( INPUT => p."name") n
    WHERE   p."deceased"            IS NULL                     -- still alive
      AND   n.value:"family"        IS NOT NULL
      AND   UPPER(n.value:"family"::string)  LIKE 'A%'           -- surname begins with A
), -------------------------------------------------------------------------------
patient_conditions AS (         -- every condition each patient carries
    SELECT  c."subject":"patientId"::string          AS patient_id ,
            c."code":"text"::string                  AS condition_text ,
            c."code":"coding"[0]:"code"::string      AS condition_code
    FROM    FHIR_SYNTHEA.FHIR_SYNTHEA.CONDITION  c
), -------------------------------------------------------------------------------
one_condition_patients AS (     -- keep only patients with exactly ONE distinct condition
    SELECT  patient_id ,
            MAX(condition_text)  AS condition_text ,
            MAX(condition_code)  AS condition_code
    FROM    patient_conditions
    GROUP BY patient_id
    HAVING  COUNT(DISTINCT condition_code) = 1
), -------------------------------------------------------------------------------
eligible_patients AS (          -- intersection of “living A-surname” & “exactly one condition”
    SELECT  l.patient_id ,
            o.condition_text ,
            o.condition_code
    FROM    living_patients       l
    JOIN    one_condition_patients o  ON l.patient_id = o.patient_id
), -------------------------------------------------------------------------------
patient_med_counts AS (         -- # of DISTINCT active meds for every patient
    SELECT  mr."subject":"patientId"::string                        AS patient_id ,
            COUNT(DISTINCT mr."medication":"codeableConcept":"coding"[0]:"code"::string) 
                      AS active_med_cnt
    FROM    FHIR_SYNTHEA.FHIR_SYNTHEA.MEDICATION_REQUEST mr
    WHERE   mr."status" = 'active'
    GROUP BY mr."subject":"patientId"::string
), -------------------------------------------------------------------------------
patient_cond_med AS (           -- merge condition with each patient’s med count
    SELECT  e.condition_text ,
            e.condition_code ,
            COALESCE(pm.active_med_cnt ,0)  AS med_cnt
    FROM    eligible_patients   e
    LEFT  JOIN patient_med_counts pm  ON e.patient_id = pm.patient_id
), -------------------------------------------------------------------------------
condition_stats AS (            -- for each condition, best (max) patient count
    SELECT  condition_text ,
            condition_code ,
            MAX(med_cnt) AS max_med_cnt
    FROM    patient_cond_med
    GROUP BY condition_text , condition_code
) ------------------------------------------------------------------------------
SELECT  condition_text ,
        condition_code
FROM    condition_stats
ORDER BY max_med_cnt DESC NULLS LAST
LIMIT 8;