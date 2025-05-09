/* 1.  Alive patients (no deceased.dateTime recorded)
   2.  Patients having any Condition whose code text/coding mentions Diabetes or Hypertension
   3.  Among those, patients with ≥ 7 different active Medication Requests
*/
SELECT COUNT(*) AS "alive_diab_htn_with_7plus_active_meds"
FROM (

    /* Patients with Diabetes or Hypertension diagnoses */
    SELECT DISTINCT
           c."subject":"patientId"::string AS patient_id
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA."CONDITION" AS c
    WHERE c."subject":"patientId" IS NOT NULL
      AND (
            LOWER(TO_VARCHAR(c."code")) LIKE '%diabet%'      -- diabetes
         OR LOWER(TO_VARCHAR(c."code")) LIKE '%hypertens%'   -- hypertension
          )
) AS diag

/* join to alive patients (no deceased element) */
JOIN (
    SELECT p."id" AS patient_id
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA."PATIENT" AS p
    WHERE p."deceased" IS NULL
) AS alive
  ON diag.patient_id = alive.patient_id

/* join to patients having ≥ 7 distinct active medications */
JOIN (
    SELECT
        mr."subject":"patientId"::string       AS patient_id,
        COUNT(DISTINCT TO_VARCHAR(mr."medication")) AS med_cnt
    FROM FHIR_SYNTHEA.FHIR_SYNTHEA."MEDICATION_REQUEST" AS mr
    WHERE mr."subject":"patientId" IS NOT NULL
      AND LOWER(mr."status") = 'active'
    GROUP BY mr."subject":"patientId"::string
    HAVING med_cnt >= 7
) AS meds
  ON diag.patient_id = meds.patient_id
;