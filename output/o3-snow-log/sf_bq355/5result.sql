WITH 
ancestor_concept AS (  -- Quinapril RxNorm concept
    SELECT "concept_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."CONCEPT"
    WHERE "vocabulary_id" = 'RxNorm'
      AND "concept_code" = '35208'
),
all_related_concepts AS (  -- Quinapril and all its related (descendant) concepts
    SELECT "descendant_concept_id" AS "concept_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."CONCEPT_ANCESTOR"
    WHERE "ancestor_concept_id" IN (SELECT "concept_id" FROM ancestor_concept)
    UNION               -- include the ancestor itself
    SELECT "concept_id" FROM ancestor_concept
),
quinapril_users AS (      -- people ever exposed to Quinapril/related drugs
    SELECT DISTINCT "person_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."DRUG_ERA"
    WHERE "drug_concept_id" IN (SELECT "concept_id" FROM all_related_concepts)
),
population_counts AS (    -- total population and user counts
    SELECT
        (SELECT COUNT(DISTINCT "person_id") FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."PERSON")       AS total_persons,
        (SELECT COUNT(DISTINCT "person_id") FROM quinapril_users)                                         AS users
)
SELECT 
    ROUND( (total_persons - users) * 100.0 / total_persons , 4) AS "percent_not_using_quinapril"
FROM population_counts;