WITH total_participants_cte AS (
  SELECT COUNT(DISTINCT "person_id") AS "total_participants"
  FROM "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."PERSON"
),
acne_concept_ids AS (
  SELECT DISTINCT cr."concept_id_2" AS "standard_concept_id"
  FROM "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."CONCEPT_RELATIONSHIP" cr
  JOIN "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."CONCEPT" c1
    ON cr."concept_id_1" = c1."concept_id"
  WHERE c1."vocabulary_id" = 'ICD10CM' AND c1."concept_code" LIKE 'L70%'
    AND cr."relationship_id" = 'Maps to'
),
acne_cte AS (
  SELECT COUNT(DISTINCT co."person_id") AS "condition_count"
  FROM "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."CONDITION_OCCURRENCE" co
  WHERE co."condition_concept_id" IN (
    SELECT "standard_concept_id" FROM acne_concept_ids
  )
),
atopic_concept_ids AS (
  SELECT DISTINCT cr."concept_id_2" AS "standard_concept_id"
  FROM "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."CONCEPT_RELATIONSHIP" cr
  JOIN "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."CONCEPT" c1
    ON cr."concept_id_1" = c1."concept_id"
  WHERE c1."vocabulary_id" = 'ICD10CM' AND c1."concept_code" LIKE 'L20%'
    AND cr."relationship_id" = 'Maps to'
),
atopic_count_cte AS (
  SELECT COUNT(DISTINCT co."person_id") AS "condition_count"
  FROM "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."CONDITION_OCCURRENCE" co
  WHERE co."condition_concept_id" IN (
    SELECT "standard_concept_id" FROM atopic_concept_ids
  )
),
psoriasis_concept_ids AS (
  SELECT DISTINCT cr."concept_id_2" AS "standard_concept_id"
  FROM "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."CONCEPT_RELATIONSHIP" cr
  JOIN "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."CONCEPT" c1
    ON cr."concept_id_1" = c1."concept_id"
  WHERE c1."vocabulary_id" = 'ICD10CM' AND c1."concept_code" LIKE 'L40%'
    AND cr."relationship_id" = 'Maps to'
),
psoriasis_cte AS (
  SELECT COUNT(DISTINCT co."person_id") AS "condition_count"
  FROM "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."CONDITION_OCCURRENCE" co
  WHERE co."condition_concept_id" IN (
    SELECT "standard_concept_id" FROM psoriasis_concept_ids
  )
),
vitiligo_concept_ids AS (
  SELECT DISTINCT cr."concept_id_2" AS "standard_concept_id"
  FROM "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."CONCEPT_RELATIONSHIP" cr
  JOIN "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."CONCEPT" c1
    ON cr."concept_id_1" = c1."concept_id"
  WHERE c1."vocabulary_id" = 'ICD10CM' AND c1."concept_code" LIKE 'L80%'
    AND cr."relationship_id" = 'Maps to'
),
vitiligo_cte AS (
  SELECT COUNT(DISTINCT co."person_id") AS "condition_count"
  FROM "CMS_DATA"."CMS_SYNTHETIC_PATIENT_DATA_OMOP"."CONDITION_OCCURRENCE" co
  WHERE co."condition_concept_id" IN (
    SELECT "standard_concept_id" FROM vitiligo_concept_ids
  )
)
SELECT
  'Acne' AS "Condition",
  ROUND((acne_cte."condition_count" * 100.0) / total_participants_cte."total_participants", 4) AS "Percentage"
FROM acne_cte, total_participants_cte
UNION ALL
SELECT
  'Atopic dermatitis' AS "Condition",
  ROUND((atopic_count_cte."condition_count" * 100.0) / total_participants_cte."total_participants", 4) AS "Percentage"
FROM atopic_count_cte, total_participants_cte
UNION ALL
SELECT
  'Psoriasis' AS "Condition",
  ROUND((psoriasis_cte."condition_count" * 100.0) / total_participants_cte."total_participants", 4) AS "Percentage"
FROM psoriasis_cte, total_participants_cte
UNION ALL
SELECT
  'Vitiligo' AS "Condition",
  ROUND((vitiligo_cte."condition_count" * 100.0) / total_participants_cte."total_participants", 4) AS "Percentage"
FROM vitiligo_cte, total_participants_cte;