WITH total_count AS (
  SELECT COUNT(DISTINCT "person_id") AS total_participants
  FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."PERSON"
),
condition_counts AS (
  SELECT 'Acne' AS "Condition", COUNT(DISTINCT co."person_id") AS condition_count
  FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."CONDITION_OCCURRENCE" co
  WHERE co."condition_concept_id" IN (
    SELECT cr."concept_id_2"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."CONCEPT" c
    JOIN CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."CONCEPT_RELATIONSHIP" cr
      ON c."concept_id" = cr."concept_id_1"
    WHERE c."concept_code" LIKE 'L70%' AND c."vocabulary_id" = 'ICD10CM'
      AND cr."relationship_id" = 'Maps to'
  )
  UNION ALL
  SELECT 'Atopic dermatitis' AS "Condition", COUNT(DISTINCT co."person_id") AS condition_count
  FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."CONDITION_OCCURRENCE" co
  WHERE co."condition_concept_id" IN (
    SELECT cr."concept_id_2"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."CONCEPT" c
    JOIN CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."CONCEPT_RELATIONSHIP" cr
      ON c."concept_id" = cr."concept_id_1"
    WHERE c."concept_code" LIKE 'L20%' AND c."vocabulary_id" = 'ICD10CM'
      AND cr."relationship_id" = 'Maps to'
  )
  UNION ALL
  SELECT 'Psoriasis' AS "Condition", COUNT(DISTINCT co."person_id") AS condition_count
  FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."CONDITION_OCCURRENCE" co
  WHERE co."condition_concept_id" IN (
    SELECT cr."concept_id_2"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."CONCEPT" c
    JOIN CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."CONCEPT_RELATIONSHIP" cr
      ON c."concept_id" = cr."concept_id_1"
    WHERE c."concept_code" LIKE 'L40%' AND c."vocabulary_id" = 'ICD10CM'
      AND cr."relationship_id" = 'Maps to'
  )
  UNION ALL
  SELECT 'Vitiligo' AS "Condition", COUNT(DISTINCT co."person_id") AS condition_count
  FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."CONDITION_OCCURRENCE" co
  WHERE co."condition_concept_id" IN (
    SELECT cr."concept_id_2"
    FROM CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."CONCEPT" c
    JOIN CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP."CONCEPT_RELATIONSHIP" cr
      ON c."concept_id" = cr."concept_id_1"
    WHERE c."concept_code" LIKE 'L80%' AND c."vocabulary_id" = 'ICD10CM'
      AND cr."relationship_id" = 'Maps to'
  )
)
SELECT cc."Condition",
       ROUND((cc.condition_count * 100.0) / tc.total_participants, 4) AS "Percentage"
FROM condition_counts cc
CROSS JOIN total_count tc;