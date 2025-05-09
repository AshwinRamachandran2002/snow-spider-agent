/*  Percentage of participants with Acne (L70*), Atopic dermatitis (L20*),
    Psoriasis (L40*) and Vitiligo (L80*) – descendants included              */
WITH anchor AS (                                  -- four header ICD-10-CM codes
    SELECT  "concept_id",
            "concept_code",
            "concept_name"
    FROM    CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT
    WHERE   "vocabulary_id"  = 'ICD10CM'
      AND   "concept_code"   IN ('L70','L20','L40','L80')
),                                                -- all ICD-10-CM child codes
icd10_descendants AS (
    SELECT  ca."ancestor_concept_id"   AS anchor_id,
            ca."descendant_concept_id" AS icd10cm_desc_id
    FROM    CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_ANCESTOR ca
    JOIN    anchor a
           ON a."concept_id" = ca."ancestor_concept_id"
    JOIN    CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT c
           ON c."concept_id" = ca."descendant_concept_id"
    WHERE   c."vocabulary_id" = 'ICD10CM'         -- keep only ICD-10-CM concepts
),                                                -- map every ICD-10-CM to STANDARD concept(s)
std_map AS (
    SELECT  d.anchor_id,
            cr."concept_id_2" AS std_concept_id
    FROM    icd10_descendants d
    JOIN    CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONCEPT_RELATIONSHIP cr
           ON cr."concept_id_1" = d.icd10cm_desc_id
          AND cr."relationship_id" = 'Maps to'
          AND cr."invalid_reason" IS NULL
),                                                -- persons having any mapped standard concept
persons_per_condition AS (
    SELECT  DISTINCT
            s.anchor_id,
            co."person_id"
    FROM    std_map s
    JOIN    CMS_DATA.CMS_SYNTHETIC_PATIENT_DATA_OMOP.CONDITION_OCCURRENCE co
           ON co."condition_concept_id" = s.std_concept_id
),                                                -- counts per disease header
counts AS (
    SELECT  a."concept_code"                      AS icd10_cm_code,
            a."concept_name"                      AS condition_group,
            COUNT(DISTINCT p."person_id")         AS participant_count
    FROM    anchor a
    LEFT JOIN persons_per_condition p
           ON p.anchor_id = a."concept_id"
    GROUP BY a."concept_code", a."concept_name"
),                                                -- denominator: unique persons across all four groups
total AS (
    SELECT  COUNT(DISTINCT "person_id") AS total_participants
    FROM    persons_per_condition
)
SELECT  c.icd10_cm_code,
        c.condition_group,
        c.participant_count,
        ROUND(c.participant_count * 100.0 / NULLIF(t.total_participants,0),4) AS percentage_of_participants
FROM    counts c
CROSS JOIN total t
ORDER BY c.icd10_cm_code;