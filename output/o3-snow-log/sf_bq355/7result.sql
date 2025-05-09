WITH quinapril_ancestor AS (
    SELECT "concept_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT
    WHERE "concept_code" = '35208'
      AND "vocabulary_id" = 'RxNorm'
),
quinapril_related AS (
    SELECT "descendant_concept_id" AS "concept_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_ANCESTOR
    WHERE "ancestor_concept_id" IN (SELECT "concept_id" FROM quinapril_ancestor)
    UNION
    SELECT "concept_id"
    FROM quinapril_ancestor
),
quinapril_users AS (
    SELECT DISTINCT "person_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.DRUG_ERA
    WHERE "drug_concept_id" IN (SELECT "concept_id" FROM quinapril_related)
),
counts AS (
    SELECT
        (SELECT COUNT(*) FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.PERSON)  AS total_persons,
        (SELECT COUNT(*) FROM quinapril_users)                                   AS users_persons
)
SELECT
    ROUND(((total_persons - users_persons) * 100.0) / total_persons, 4) AS "percentage_not_using_quinapril"
FROM counts;