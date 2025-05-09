WITH quinapril_related_concepts AS (
    /* All concepts that map to Quinapril (ingredient concept 35208) */
    SELECT DISTINCT "descendant_concept_id" AS concept_id
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_ANCESTOR
    WHERE "ancestor_concept_id" = 35208
),
quinapril_users AS (
    /* Persons with any Quinapril (or related) drug era */
    SELECT DISTINCT "person_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.DRUG_ERA
    WHERE "drug_concept_id" IN (SELECT concept_id FROM quinapril_related_concepts)
),
population_counts AS (
    SELECT
        (SELECT COUNT(*) FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.PERSON) AS total_participants,
        (SELECT COUNT(*) FROM quinapril_users)                                  AS quinapril_users
)
SELECT
    ROUND( (total_participants - quinapril_users) * 100.0 / total_participants, 4 )
        AS percent_participants_not_using_quinapril
FROM population_counts;