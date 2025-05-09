WITH patients_a AS (   -- living patients whose last name starts with “A”
    SELECT  p."id" AS patient_id
    FROM    FHIR_SYNTHEA.FHIR_SYNTHEA.PATIENT p,
            LATERAL FLATTEN(INPUT => p."name") n
    WHERE   p."deceased" IS NULL
      AND   UPPER(n.value:"family"::string) LIKE 'A%'
),
one_condition_patients AS (      -- all conditions for those patients
    SELECT  c."subject":"patientId"::string                       AS patient_id,
            c."code":"coding"[0]:"code"::string                   AS condition_code,
            COALESCE(c."code":"text"::string,
                     c."code":"coding"[0]:"display"::string)      AS condition_text
    FROM    FHIR_SYNTHEA.FHIR_SYNTHEA.CONDITION c
            JOIN patients_a p
              ON p.patient_id = c."subject":"patientId"::string
),
qualified_patients AS (          -- keep only patients with exactly one distinct condition
    SELECT  patient_id
    FROM    one_condition_patients
    GROUP BY patient_id
    HAVING  COUNT(DISTINCT condition_code) = 1
),
patient_condition AS (           -- each qualified patient with their single condition
    SELECT  DISTINCT oc.patient_id,
            oc.condition_code,
            oc.condition_text
    FROM    one_condition_patients oc
            JOIN qualified_patients qp
              ON oc.patient_id = qp.patient_id
),
active_meds AS (                 -- distinct active medication codes per qualified patient
    SELECT  DISTINCT
            mr."subject":"patientId"::string                       AS patient_id,
            mr."medication":"codeableConcept":"coding"[0]:"code"::string AS medication_code
    FROM    FHIR_SYNTHEA.FHIR_SYNTHEA.MEDICATION_REQUEST mr
            JOIN qualified_patients qp
              ON qp.patient_id = mr."subject":"patientId"::string
    WHERE   LOWER(mr."status") = 'active'
),
med_counts AS (                  -- number of active meds per patient
    SELECT  patient_id,
            COUNT(DISTINCT medication_code) AS med_cnt
    FROM    active_meds
    GROUP BY patient_id
),
condition_max_meds AS (          -- max #active meds for each condition across patients
    SELECT  pc.condition_code,
            pc.condition_text,
            MAX(COALESCE(mc.med_cnt, 0)) AS max_active_meds
    FROM    patient_condition pc
            LEFT JOIN med_counts mc
              ON pc.patient_id = mc.patient_id
    GROUP BY pc.condition_code, pc.condition_text
)
SELECT  condition_text        AS CONDITION,
        condition_code        AS CODE,
        max_active_meds       AS MAX_ACTIVE_MEDICATIONS
FROM    condition_max_meds
ORDER BY max_active_meds DESC NULLS LAST,
         condition_code
LIMIT 8;