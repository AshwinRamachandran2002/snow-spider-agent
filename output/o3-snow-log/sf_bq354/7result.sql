/*---------------------------------------------------------------------------
  Percentage of participants with Acne (L70*), Atopic Dermatitis (L20*),
  Psoriasis (L40*), and Vitiligo (L80*), including all ICD-10-CM
  sub-categories.  ICD-10-CM codes are first mapped to their standard
  SNOMED concepts (“Maps to” relationship) and then linked to the
  CONDITION_OCCURRENCE table to count unique persons.
---------------------------------------------------------------------------*/
WITH ICD10_CM_CODES AS (          -- all ICD-10-CM codes beginning with L70/L20/L40/L80
    SELECT  "concept_id",
            CASE
                 WHEN "concept_code" LIKE 'L70%' THEN 'Acne'
                 WHEN "concept_code" LIKE 'L20%' THEN 'Atopic Dermatitis'
                 WHEN "concept_code" LIKE 'L40%' THEN 'Psoriasis'
                 WHEN "concept_code" LIKE 'L80%' THEN 'Vitiligo'
            END                                   AS "condition_name"
    FROM    CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT
    WHERE   "vocabulary_id" = 'ICD10CM'
      AND   ( "concept_code" LIKE 'L70%'
           OR "concept_code" LIKE 'L20%'
           OR "concept_code" LIKE 'L40%'
           OR "concept_code" LIKE 'L80%' )
),
SNOMED_MAP AS (                   -- map each ICD-10-CM code to its standard SNOMED concept(s)
    SELECT  i."condition_name",
            cr."concept_id_2"            AS "snomed_concept_id"
    FROM    ICD10_CM_CODES                                   i
    JOIN    CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_RELATIONSHIP  cr
           ON cr."concept_id_1"   = i."concept_id"
          AND cr."relationship_id" = 'Maps to'
),
CONDITION_PERSONS AS (            -- persons having any of the mapped SNOMED concepts
    SELECT  sm."condition_name",
            co."person_id"
    FROM    SNOMED_MAP                                            sm
    JOIN    CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONDITION_OCCURRENCE  co
           ON co."condition_concept_id" = sm."snomed_concept_id"
    GROUP BY sm."condition_name", co."person_id"
),
COUNTS AS (                       -- number of unique persons per condition
    SELECT  "condition_name",
            COUNT(*)  AS "condition_persons"
    FROM    CONDITION_PERSONS
    GROUP BY "condition_name"
),
TOTAL AS (                        -- total number of participants
    SELECT  COUNT(DISTINCT "person_id") AS "total_persons"
    FROM    CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.PERSON
)
SELECT  c."condition_name"                                   AS "condition",
        ROUND( c."condition_persons" * 100.0
               / t."total_persons", 4 )                      AS "participants_percentage"
FROM    COUNTS  c
CROSS   JOIN TOTAL  t
ORDER BY "participants_percentage" DESC NULLS LAST;