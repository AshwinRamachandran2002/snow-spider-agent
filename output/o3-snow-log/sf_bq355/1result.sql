WITH "quinapril_related" AS (          -- all concepts for quinapril and its combinations
    SELECT "descendant_concept_id" AS "concept_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_ANCESTOR
    WHERE "ancestor_concept_id" = 35208                        -- RxCUI for Quinapril
),
"quinapril_users" AS (                 -- every person ever exposed to any of those concepts
    SELECT DISTINCT "person_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.DRUG_ERA
    WHERE "drug_concept_id" IN (SELECT "concept_id" FROM "quinapril_related")
    UNION
    SELECT DISTINCT "person_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.DRUG_EXPOSURE
    WHERE "drug_concept_id" IN (SELECT "concept_id" FROM "quinapril_related")
),
"population" AS (                      -- total synthetic cohort size
    SELECT COUNT(*) AS "total_participants"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.PERSON
),
"users_count" AS (                     -- number of participants using quinapril or related meds
    SELECT COUNT(*) AS "using_participants"
    FROM "quinapril_users"
)
SELECT
    "total_participants",
    "total_participants" - "using_participants" AS "participants_not_using",
    ROUND(
        100.0 * ("total_participants" - "using_participants") / "total_participants",
        4
    ) AS "percentage_not_using"
FROM "population", "users_count";