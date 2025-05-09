WITH root_codes AS (          /* 1. four ICD-10-CM root codes */
    SELECT  "concept_id",
            "concept_code",
            "concept_name"
    FROM    CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT
    WHERE   "vocabulary_id" = 'ICD10CM'
      AND   "concept_code"  IN ('L70','L20','L40','L80')          -- acne, atopic dermatitis, psoriasis, vitiligo
),
icd_descendants AS (          /* 2. each root plus all of its ICD-10-CM descendants */
    SELECT  r."concept_code"          AS "disease_code",
            ca."descendant_concept_id" AS "icd10cm_concept_id"
    FROM    root_codes               r
    JOIN    CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_ANCESTOR ca
           ON ca."ancestor_concept_id" = r."concept_id"
),
mapped_standard AS (          /* 3. map every ICD-10-CM code to its standard concept */
    SELECT  DISTINCT
            d."disease_code",
            cr."concept_id_2"         AS "standard_concept_id"
    FROM    icd_descendants                               d
    JOIN    CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_RELATIONSHIP cr
           ON cr."concept_id_1"  = d."icd10cm_concept_id"
          AND cr."relationship_id" = 'Maps to'
          AND cr."invalid_reason"  IS NULL
),
disease_persons AS (          /* 4. all participants with any mapped concept */
    SELECT  DISTINCT
            m."disease_code",
            co."person_id"
    FROM    mapped_standard                             m
    JOIN    CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONDITION_OCCURRENCE co
           ON co."condition_concept_id" = m."standard_concept_id"
),
disease_counts AS (           /* 5. patient counts per disorder */
    SELECT  "disease_code",
            COUNT(DISTINCT "person_id") AS "patient_count"
    FROM    disease_persons
    GROUP BY "disease_code"
),
total_participants AS (       /* 6. overall study population */
    SELECT  COUNT(DISTINCT "person_id") AS "total_count"
    FROM    CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.PERSON
)
SELECT
       rc."concept_name"                              AS "disease_name",
       rc."concept_code"                              AS "icd10cm_root",
       COALESCE(dc."patient_count", 0)                AS "patient_count",
       ROUND( COALESCE(dc."patient_count", 0) * 100.0 / tp."total_count", 4)
                                                     AS "percentage_of_participants"
FROM   root_codes            rc
LEFT   JOIN disease_counts   dc ON rc."concept_code" = dc."disease_code"
CROSS  JOIN total_participants tp
ORDER  BY rc."concept_code";