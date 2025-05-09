WITH quinapril_ancestor AS (   -- RxNorm ingredient concept for Quinapril
    SELECT "concept_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT
    WHERE "concept_code" = '35208'
      AND "vocabulary_id" = 'RxNorm'
),
quinapril_descendants AS (     -- Quinapril plus every related (descendant) concept
    SELECT ca."descendant_concept_id" AS "concept_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_ANCESTOR ca
    JOIN quinapril_ancestor qa
      ON ca."ancestor_concept_id" = qa."concept_id"
    UNION
    SELECT "concept_id" FROM quinapril_ancestor               -- include the ancestor itself
),
quinapril_users AS (           -- participants who ever used Quinapril or a descendant drug
    SELECT DISTINCT de."person_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.DRUG_EXPOSURE de
    WHERE de."drug_concept_id" IN (SELECT "concept_id" FROM quinapril_descendants)
),
counts AS (                    -- total participants and users
    SELECT
        (SELECT COUNT(DISTINCT p."person_id")
         FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.PERSON p)  AS "total_participants",
        (SELECT COUNT(*) FROM quinapril_users)                   AS "users"
)
SELECT
    ROUND( (("total_participants" - "users") * 100.0)
           / NULLIF("total_participants",0), 4) AS "percent_not_using_quinapril"
FROM counts;