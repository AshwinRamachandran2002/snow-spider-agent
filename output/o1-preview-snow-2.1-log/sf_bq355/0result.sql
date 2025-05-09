WITH quinapril_concepts AS (
    SELECT "concept_id"
    FROM "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."CONCEPT"
    WHERE "concept_name" ILIKE '%quinapril%'
),
total_participants AS (
    SELECT COUNT(DISTINCT "person_id") AS total_persons
    FROM "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."PERSON"
),
participants_using_quinapril AS (
    SELECT COUNT(DISTINCT "person_id") AS persons_using_quinapril
    FROM "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."DRUG_EXPOSURE"
    WHERE "drug_concept_id" IN (SELECT "concept_id" FROM quinapril_concepts)
)
SELECT
    ROUND(
        (
            (tp.total_persons - puq.persons_using_quinapril) * 100.0
            / tp.total_persons
        ),
        4
    ) AS "Percentage_not_using_quinapril"
FROM total_participants tp, participants_using_quinapril puq;