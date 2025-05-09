WITH "ROOT_CODES" AS (
    SELECT 'L70' AS "ICD_ROOT", 'Acne'               AS "DISEASE" UNION ALL
    SELECT 'L20',              'Atopic Dermatitis'               UNION ALL
    SELECT 'L40',              'Psoriasis'                       UNION ALL
    SELECT 'L80',              'Vitiligo'
),
/* 1.  All ICD-10-CM codes (including sub-categories) for each root  */
"ICD_CONCEPTS" AS (
    SELECT r."ICD_ROOT",
           c."concept_id"
    FROM "ROOT_CODES" r
    JOIN CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT c
         ON c."vocabulary_id" = 'ICD10CM'
        AND c."concept_code"  LIKE r."ICD_ROOT" || '%'
        AND c."invalid_reason" IS NULL
),
/* 2.  Map those non-standard ICD-10-CM codes to STANDARD concepts (SNOMED etc.) */
"MAPPED_STANDARD" AS (
    SELECT DISTINCT ic."ICD_ROOT",
           cr."concept_id_2" AS "STANDARD_CONCEPT_ID"
    FROM "ICD_CONCEPTS" ic
    JOIN CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_RELATIONSHIP cr
         ON cr."concept_id_1"   = ic."concept_id"
        AND cr."relationship_id" = 'Maps to'
        AND cr."invalid_reason"  IS NULL
),
/* 3.  Get every descendant of each standard concept (includes the concept itself) */
"ALL_DESCENDANTS" AS (
    SELECT DISTINCT ms."ICD_ROOT",
           ca."descendant_concept_id" AS "CONCEPT_ID"
    FROM "MAPPED_STANDARD" ms
    JOIN CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_ANCESTOR ca
         ON ca."ancestor_concept_id" = ms."STANDARD_CONCEPT_ID"
),
/* 4.  Identify unique persons with at least one of those condition concepts */
"CONDITION_PERSONS" AS (
    SELECT ad."ICD_ROOT",
           co."person_id"
    FROM "ALL_DESCENDANTS" ad
    JOIN CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONDITION_OCCURRENCE co
         ON co."condition_concept_id" = ad."CONCEPT_ID"
    GROUP BY ad."ICD_ROOT", co."person_id"
),
/* 5.  Count persons per disease group */
"COUNTS" AS (
    SELECT "ICD_ROOT",
           COUNT(DISTINCT "person_id") AS "CONDITION_PERSONS"
    FROM "CONDITION_PERSONS"
    GROUP BY "ICD_ROOT"
),
/* 6.  Total number of participants in the database */
"TOTAL" AS (
    SELECT COUNT(DISTINCT "person_id") AS "TOTAL_PERSONS"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.PERSON
)
SELECT rc."DISEASE",
       c."CONDITION_PERSONS",
       t."TOTAL_PERSONS",
       ROUND(c."CONDITION_PERSONS" * 100.0 / t."TOTAL_PERSONS", 4) AS "PERCENTAGE_OF_PARTICIPANTS"
FROM "COUNTS" c
JOIN "ROOT_CODES" rc
  ON rc."ICD_ROOT" = c."ICD_ROOT",
"TOTAL" t
ORDER BY "PERCENTAGE_OF_PARTICIPANTS" DESC NULLS LAST;