WITH
-- Step 1: Map ICD-10-CM codes to SNOMED concept IDs
icd10_to_snomed AS (
  SELECT
    icd."concept_id" AS "icd_concept_id",
    icd."concept_code" AS "icd_code",
    snomed."concept_id" AS "snomed_concept_id",
    CASE
      WHEN icd."concept_code" LIKE 'L70%' THEN 'Acne'
      WHEN icd."concept_code" LIKE 'L20%' THEN 'Atopic dermatitis'
      WHEN icd."concept_code" LIKE 'L40%' THEN 'Psoriasis'
      WHEN icd."concept_code" LIKE 'L80%' THEN 'Vitiligo'
    END AS "Condition"
  FROM
    "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."CONCEPT" icd
  JOIN
    "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."CONCEPT_RELATIONSHIP" cr
    ON icd."concept_id" = cr."concept_id_1"
    AND cr."relationship_id" = 'Maps to'
  JOIN
    "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."CONCEPT" snomed
    ON cr."concept_id_2" = snomed."concept_id"
  WHERE
    icd."vocabulary_id" = 'ICD10CM'
    AND (
      icd."concept_code" LIKE 'L70%' OR
      icd."concept_code" LIKE 'L20%' OR
      icd."concept_code" LIKE 'L40%' OR
      icd."concept_code" LIKE 'L80%'
    )
),
-- Step 2: Get total number of patients
total_patients AS (
  SELECT COUNT(DISTINCT "person_id") AS "total"
  FROM "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."PERSON"
),
-- Step 3: Count patients per condition
condition_counts AS (
  SELECT
    snomed_map."Condition",
    COUNT(DISTINCT o."person_id") AS "patient_count"
  FROM
    "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."CONDITION_OCCURRENCE" o
  JOIN
    icd10_to_snomed snomed_map
    ON o."condition_concept_id" = snomed_map."snomed_concept_id"
  GROUP BY
    snomed_map."Condition"
)
SELECT
  cc."Condition",
  ROUND((cc."patient_count" * 100.0) / tp."total", 4) AS "Percentage"
FROM
  condition_counts cc,
  total_patients tp
ORDER BY
  cc."Condition";