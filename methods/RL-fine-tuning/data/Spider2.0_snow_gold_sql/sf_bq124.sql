SELECT COUNT(DISTINCT p."id") AS "Number_of_patients"
FROM "FHIR_SYNTHEA"."FHIR_SYNTHEA"."PATIENT" p
JOIN (
  SELECT DISTINCT
    COALESCE(
      c."subject":"patientId"::STRING,
      SPLIT_PART(c."subject":"reference"::STRING, '/', 2)
    ) AS "patient_id"
  FROM "FHIR_SYNTHEA"."FHIR_SYNTHEA"."CONDITION" c,
    LATERAL FLATTEN(input => c."code":"coding") f_coding
  WHERE LOWER(f_coding.value:"display"::STRING) LIKE '%diabetes%'
     OR LOWER(f_coding.value:"display"::STRING) LIKE '%hypertension%'
) cond ON p."id" = cond."patient_id"
JOIN (
  SELECT
    COALESCE(
      mr."subject":"patientId"::STRING,
      SPLIT_PART(mr."subject":"reference"::STRING, '/', 2)
    ) AS "patient_id"
  FROM "FHIR_SYNTHEA"."FHIR_SYNTHEA"."MEDICATION_REQUEST" mr,
    LATERAL FLATTEN(input => mr."medication":"codeableConcept":"coding") f_med
  WHERE LOWER(mr."status") = 'active'
  GROUP BY 1
  HAVING COUNT(DISTINCT f_med.value:"code"::STRING) >= 7
) med ON p."id" = med."patient_id"
WHERE p."deceased" IS NULL;