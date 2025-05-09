WITH
  total_participants AS (
    SELECT COUNT(DISTINCT "person_id") AS total
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.PERSON
  ),
  quinapril_concept_ids AS (
    SELECT DISTINCT "descendant_concept_id" AS concept_id
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_ANCESTOR
    WHERE "ancestor_concept_id" = 1331235  -- Quinapril concept_id
  ),
  participants_using_quinapril AS (
    SELECT DISTINCT de."person_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.DRUG_EXPOSURE de
    WHERE de."drug_concept_id" IN (SELECT concept_id FROM quinapril_concept_ids)
  ),
  num_participants_using_quinapril AS (
    SELECT COUNT(DISTINCT "person_id") AS num_using_quinapril
    FROM participants_using_quinapril
  )
SELECT
  ROUND(
    100.0 * (
      (tp.total - npuq.num_using_quinapril) / tp.total
    ), 4
  ) AS "Percentage_not_using_quinapril"
FROM
  total_participants tp,
  num_participants_using_quinapril npuq;