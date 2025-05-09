WITH
-- 1.  All concept_ids for Quinapril (RxCUI 35208) and every related formulation/strength
"CONCEPT_SET" AS (
    SELECT "descendant_concept_id" AS "concept_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."CONCEPT_ANCESTOR"
    WHERE "ancestor_concept_id" = 35208
    
    UNION          -- include the ancestor itself
    SELECT 35208   -- Quinapril RxCUI
),

-- 2.  Every person who was exposed to one of those concepts (any time)
"QUINAPRIL_USERS" AS (
    SELECT DISTINCT "person_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."DRUG_ERA"
    WHERE "drug_concept_id" IN (SELECT "concept_id" FROM "CONCEPT_SET")
),

-- 3.  Counts of total participants and participants using Quinapril
"COUNTS" AS (
    SELECT
        (SELECT COUNT(DISTINCT "person_id")
         FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."PERSON")                                       AS "total_persons",
        (SELECT COUNT(*) FROM "QUINAPRIL_USERS")                                                       AS "users"
)

-- 4.  Final percentage of participants NOT using Quinapril (and related meds)
SELECT
    ROUND( (("total_persons" - "users") * 100.0) / "total_persons", 4) AS "percentage_not_using_quinapril"
FROM "COUNTS";