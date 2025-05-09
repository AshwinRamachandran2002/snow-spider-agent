SELECT 
    ROUND(((total.total_participants - exposed.participants_exposed_to_quinapril) * 100.0) / total.total_participants, 4) AS "Percentage_not_using_quinapril"
FROM 
    (SELECT COUNT(DISTINCT "person_id") AS total_participants
     FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.PERSON) total,
    (SELECT COUNT(DISTINCT "person_id") AS participants_exposed_to_quinapril
     FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.DRUG_EXPOSURE
     WHERE "drug_concept_id" IN (
         SELECT DISTINCT "descendant_concept_id"
         FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_ANCESTOR
         WHERE "ancestor_concept_id" = (
             SELECT "concept_id"
             FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT
             WHERE "concept_code" = '35208' AND "vocabulary_id" = 'RxNorm'
         )
     )
    ) exposed;