WITH
-- 1. Get the concept_id for Quinapril (RxCUI 35208)
quinapril_root AS (
    SELECT "concept_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT
    WHERE "concept_code" = '35208'
),

-- 2. All descendant concepts (forms, strengths, packs) of Quinapril plus the root itself
quinapril_all_concepts AS (
    SELECT "descendant_concept_id" AS "concept_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_ANCESTOR
    WHERE "ancestor_concept_id" IN (SELECT "concept_id" FROM quinapril_root)
    UNION
    SELECT "concept_id" FROM quinapril_root
),

-- 3. Patients with any drug exposure of Quinapril or its related products
quinapril_users AS (
    SELECT DISTINCT "person_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.DRUG_EXPOSURE
    WHERE "drug_concept_id" IN (SELECT "concept_id" FROM quinapril_all_concepts)
),

-- 4. Totals: overall participant count and users count
totals AS (
    SELECT
        (SELECT COUNT(DISTINCT "person_id")
         FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.PERSON)         AS "total_participants",
        (SELECT COUNT(*) FROM quinapril_users)                         AS "quinapril_users"
)

-- 5. Calculate percentage not using Quinapril
SELECT
    ROUND(
        ("total_participants" - "quinapril_users") * 100.0
        / "total_participants",
        4
    ) AS "percentage_not_using_quinapril"
FROM totals;