-- Task: Please tell me the number of participants using quinapril and related medications (Quinapril concept_id: 1331235).

WITH
  quinapril_concept_ids AS (
    SELECT DISTINCT "descendant_concept_id" AS "concept_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_ANCESTOR
    WHERE "ancestor_concept_id" = 1331235  -- Quinapril concept_id
  )
SELECT COUNT(DISTINCT de."person_id") AS "num_using_quinapril"
FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.DRUG_EXPOSURE de
WHERE de."drug_concept_id" IN (SELECT "concept_id" FROM quinapril_concept_ids);