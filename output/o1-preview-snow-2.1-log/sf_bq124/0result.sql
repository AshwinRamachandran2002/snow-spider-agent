SELECT COUNT(DISTINCT p."patient_id") AS "Number_of_patients"
FROM (
  SELECT p."id" AS "patient_id"
  FROM FHIR_SYNTHEA.FHIR_SYNTHEA.PATIENT p
  WHERE p."deceased" IS NULL
    AND p."id" IS NOT NULL
) AS p
INNER JOIN (
  SELECT DISTINCT
    CASE
      WHEN c."subject":"reference" IS NOT NULL THEN SPLIT_PART(c."subject":"reference"::STRING, '/', 2)
      WHEN c."subject":"patientId" IS NOT NULL THEN c."subject":"patientId"::STRING
      ELSE NULL
    END AS "patient_id"
  FROM
    FHIR_SYNTHEA.FHIR_SYNTHEA.CONDITION c,
    LATERAL FLATTEN(INPUT => c."code":"coding") code_coding
  WHERE
    (
      LOWER(code_coding.value:"display"::STRING) LIKE '%diabetes%'
      OR LOWER(code_coding.value:"display"::STRING) LIKE '%hypertension%'
    )
    AND (
      c."subject":"reference" IS NOT NULL
      OR c."subject":"patientId" IS NOT NULL
    )
) AS c ON p."patient_id" = c."patient_id"
INNER JOIN (
  SELECT
    CASE
      WHEN mr."subject":"reference" IS NOT NULL THEN SPLIT_PART(mr."subject":"reference"::STRING, '/', 2)
      WHEN mr."subject":"patientId" IS NOT NULL THEN mr."subject":"patientId"::STRING
      ELSE NULL
    END AS "patient_id"
  FROM
    FHIR_SYNTHEA.FHIR_SYNTHEA.MEDICATION_REQUEST mr
  WHERE
    mr."subject":"reference" IS NOT NULL
    OR mr."subject":"patientId" IS NOT NULL
  GROUP BY 1
  HAVING COUNT(*) >= 7
) AS m ON p."patient_id" = m."patient_id";