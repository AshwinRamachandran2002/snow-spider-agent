WITH quinapril_ingredient AS (
    SELECT "concept_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT
    WHERE "vocabulary_id" = 'RxNorm'
      AND "concept_code" = '35208'           -- RxCUI for Quinapril
),
quinapril_concepts AS (                      -- ingredient + all descendant drug concepts
    SELECT ca."descendant_concept_id" AS "concept_id"
    FROM quinapril_ingredient qi
    JOIN CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_ANCESTOR ca
      ON ca."ancestor_concept_id" = qi."concept_id"
    UNION
    SELECT "concept_id" FROM quinapril_ingredient
),
users AS (                                   -- participants with any quinapril drug era
    SELECT DISTINCT de."person_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.DRUG_ERA de
    JOIN quinapril_concepts qc
      ON de."drug_concept_id" = qc."concept_id"
),
persons AS (                                 -- all participants in the dataset
    SELECT DISTINCT "person_id"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.PERSON
),
counts AS (                                  -- tally users and total
    SELECT
        (SELECT COUNT(*) FROM persons) AS total_persons,
        (SELECT COUNT(*) FROM users)   AS users
)
SELECT
    ROUND(((total_persons - users) * 100.0) / total_persons, 4)
        AS "PCT_PARTICIPANTS_NOT_USING_QUINAPRIL"
FROM counts;