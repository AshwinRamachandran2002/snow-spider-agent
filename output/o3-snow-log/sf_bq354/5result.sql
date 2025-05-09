/*  Percentage of participants with Acne (L70), Atopic Dermatitis (L20),
    Psoriasis (L40) and Vitiligo (L80) – including every ICD-10-CM
    sub-category, mapped to standard OMOP Condition concepts plus all
    descendant concepts                                                 */

WITH root_codes AS (
    SELECT 'L70' AS code_prefix , 'Acne'              AS disease UNION ALL
    SELECT 'L20'               , 'Atopic Dermatitis'  UNION ALL
    SELECT 'L40'               , 'Psoriasis'          UNION ALL
    SELECT 'L80'               , 'Vitiligo'
)

/* 1.  All valid (non-standard) ICD-10-CM concepts whose codes start with
       each root code prefix                                            */
, icd10_non_std AS (
    SELECT
        r.code_prefix ,
        r.disease     ,
        c."concept_id"
    FROM   root_codes r
    JOIN   CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT c
           ON  c."vocabulary_id"  = 'ICD10CM'
           AND c."concept_code"   LIKE r.code_prefix || '%'
           AND c."invalid_reason" IS NULL
)

/* 2.  Map those ICD-10-CM codes to standard OMOP Condition concepts     */
, mapped_std AS (
    SELECT DISTINCT
        r.code_prefix ,
        r.disease     ,
        cr."concept_id_2" AS standard_concept_id
    FROM   icd10_non_std r
    JOIN   CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_RELATIONSHIP cr
           ON  cr."concept_id_1"   = r."concept_id"
           AND cr."relationship_id" = 'Maps to'
           AND cr."invalid_reason"  IS NULL
    JOIN   CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT c2
           ON  c2."concept_id"       = cr."concept_id_2"
           AND c2."standard_concept" = 'S'
           AND c2."domain_id"        = 'Condition'
           AND c2."invalid_reason"   IS NULL
)

/* 3.  Include every descendant concept of each standard concept         */
, all_condition_concepts AS (
    /* the mapped standard concepts themselves */
    SELECT
        code_prefix ,
        disease     ,
        standard_concept_id AS concept_id
    FROM   mapped_std
    UNION ALL
    /* all descendants */
    SELECT
        m.code_prefix ,
        m.disease     ,
        ca."descendant_concept_id" AS concept_id
    FROM   mapped_std m
    JOIN   CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_ANCESTOR ca
           ON  ca."ancestor_concept_id" = m.standard_concept_id
    JOIN   CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT cd
           ON  cd."concept_id"       = ca."descendant_concept_id"
           AND cd."standard_concept" = 'S'
           AND cd."domain_id"        = 'Condition'
           AND cd."invalid_reason"   IS NULL
)

/* 4.  Count distinct participants having any of those concepts          */
, condition_counts AS (
    SELECT
        ac.disease ,
        COUNT(DISTINCT co."person_id") AS participants_with_condition
    FROM   all_condition_concepts ac
    JOIN   CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONDITION_OCCURRENCE co
           ON  co."condition_concept_id" = ac.concept_id
    GROUP BY ac.disease
)

/* 5.  Total number of participants in the PERSON table                  */
, total_participants AS (
    SELECT COUNT(DISTINCT "person_id") AS total_persons
    FROM   CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.PERSON
)

/* 6.  Final report                                                      */
SELECT
    cc.disease                               AS "DISEASE",
    cc.participants_with_condition           AS "PARTICIPANTS_WITH_CONDITION",
    tp.total_persons                         AS "TOTAL_PARTICIPANTS",
    ROUND(cc.participants_with_condition * 100.0 / tp.total_persons , 4)
                                             AS "PERCENTAGE_OF_PARTICIPANTS"
FROM   condition_counts cc
CROSS  JOIN total_participants tp
ORDER  BY "PERCENTAGE_OF_PARTICIPANTS" DESC NULLS LAST;