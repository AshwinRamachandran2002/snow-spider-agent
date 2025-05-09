/*  Pairs of embedding-medium and staining code meanings (SCT coded)
    that occur together in the SAME SM-modality instance               */

WITH prep_items AS (      /* coded content–items from specimen preparation */
    SELECT
        t."SOPInstanceUID",
        LOWER( ci.value:"ConceptNameCodeSequence"[0]:"CodeMeaning"::STRING )  AS concept_name_lc,
        LOWER( ci.value:"ConceptCodeSequence"[0]:"CodeMeaning"::STRING )      AS code_meaning_lc,
        ci.value:"ConceptCodeSequence"[0]:"CodeMeaning"::STRING              AS code_meaning,
        ci.value:"ConceptCodeSequence"[0]:"CodingSchemeDesignator"::STRING   AS coding_scheme
    FROM IDC.IDC_V17.DICOM_ALL t,
         LATERAL FLATTEN( INPUT => t."SpecimenDescriptionSequence")          sd,
         LATERAL FLATTEN( INPUT => sd.value:"SpecimenPreparationSequence")   sp,
         LATERAL FLATTEN( INPUT => sp.value:"SpecimenPreparationStepContentItemSequence") ci
    WHERE t."Modality" = 'SM'
      AND t."SpecimenDescriptionSequence" IS NOT NULL
      AND ci.value:"ConceptCodeSequence"[0] IS NOT NULL
      AND ci.value:"ConceptCodeSequence"[0]:"CodingSchemeDesignator"::STRING = 'SCT'
),

embedding AS (            /* embedding-medium items                        */
    SELECT DISTINCT
           "SOPInstanceUID",
           code_meaning                  AS embedding_medium
    FROM prep_items
    WHERE concept_name_lc LIKE '%embedding%'      -- “embedding medium”
),

staining AS (             /* staining items (various naming patterns)      */
    SELECT DISTINCT
           "SOPInstanceUID",
           code_meaning                  AS staining_substance
    FROM prep_items
    WHERE  concept_name_lc LIKE '%stain%'          -- “staining technique/substance”
        OR code_meaning_lc LIKE '%stain%'          -- some use generic “Staining”
),

instance_pairs AS (       /* match embedding + staining in same instance   */
    SELECT
        e."SOPInstanceUID",
        e.embedding_medium,
        s.staining_substance
    FROM embedding e
    JOIN staining  s
      ON e."SOPInstanceUID" = s."SOPInstanceUID"
)

SELECT
    embedding_medium,
    staining_substance,
    COUNT(*) AS pair_occurrences
FROM instance_pairs
GROUP BY
    embedding_medium,
    staining_substance
ORDER BY
    pair_occurrences DESC NULLS LAST;