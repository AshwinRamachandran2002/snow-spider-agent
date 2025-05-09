WITH alive AS (                                                              -- living patients
    SELECT "id" AS patient_id
    FROM   FHIR_SYNTHEA.FHIR_SYNTHEA."PATIENT"
    WHERE  "deceased" IS NULL
),

dx AS (                                                                     -- diabetes OR hypertension diagnosis
    /* look at each coding.display inside the code object */
    SELECT DISTINCT
           c."subject":patientId::string AS patient_id
    FROM   FHIR_SYNTHEA.FHIR_SYNTHEA."CONDITION"  c,
           LATERAL FLATTEN( INPUT => c."code":coding ) f
    WHERE  LOWER(f.value:display::string) LIKE '%diabetes%' 
       OR  LOWER(f.value:display::string) LIKE '%hypertension%'

    UNION                                                                   
    /* fall-back to the free-text field inside code.text */
    SELECT DISTINCT
           c."subject":patientId::string AS patient_id
    FROM   FHIR_SYNTHEA.FHIR_SYNTHEA."CONDITION"  c
    WHERE  LOWER(c."code":text::string) LIKE '%diabetes%' 
       OR  LOWER(c."code":text::string) LIKE '%hypertension%'
),

meds AS (                                                                   -- ≥7 distinct active meds
    SELECT
           mr."subject":patientId::string                AS patient_id,
           COUNT(DISTINCT f.value:code::string)          AS active_med_cnt
    FROM   FHIR_SYNTHEA.FHIR_SYNTHEA."MEDICATION_REQUEST" mr,
           LATERAL FLATTEN( INPUT => mr."medication":codeableConcept:coding ) f
    WHERE  mr."status" = 'active'
    GROUP  BY patient_id
    HAVING COUNT(DISTINCT f.value:code::string) >= 7
)

SELECT COUNT(DISTINCT a.patient_id) AS alive_patients_with_dx_and_7_plus_active_meds
FROM   alive a
JOIN   dx    d ON a.patient_id = d.patient_id
JOIN   meds  m ON a.patient_id = m.patient_id;