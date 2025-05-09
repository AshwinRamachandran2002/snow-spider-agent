WITH per_instance AS (
    SELECT
        d."SOPInstanceUID",
        MAX(
            CASE
                WHEN LOWER(ci.value:"ConceptNameCodeSequence"[0]:"CodeMeaning"::STRING) LIKE '%embedding%'
                     AND ci.value:"ConceptCodeSequence"[0]:"CodingSchemeDesignator"::STRING = 'SCT'
                THEN ci.value:"ConceptCodeSequence"[0]:"CodeMeaning"::STRING
            END
        ) AS "embedding_medium_code_meaning",
        MAX(
            CASE
                WHEN (LOWER(ci.value:"ConceptNameCodeSequence"[0]:"CodeMeaning"::STRING) LIKE '%stain%'
                      OR LOWER(ci.value:"ConceptCodeSequence"[0]:"CodeMeaning"::STRING)  LIKE '%stain%')
                     AND ci.value:"ConceptCodeSequence"[0]:"CodingSchemeDesignator"::STRING = 'SCT'
                THEN ci.value:"ConceptCodeSequence"[0]:"CodeMeaning"::STRING
            END
        ) AS "staining_substance_code_meaning"
    FROM "IDC"."IDC_V17"."DICOM_METADATA" d,
         LATERAL FLATTEN(input => d."SpecimenDescriptionSequence")                     sd,
         LATERAL FLATTEN(input => sd.value:"SpecimenPreparationSequence")              sp,
         LATERAL FLATTEN(input => sp.value:"SpecimenPreparationStepContentItemSequence") ci
    WHERE d."Modality" = 'SM'
    GROUP BY d."SOPInstanceUID"
)

SELECT
    "embedding_medium_code_meaning",
    "staining_substance_code_meaning",
    COUNT(*) AS "occurrence_count"
FROM per_instance
WHERE "embedding_medium_code_meaning" IS NOT NULL
  AND "staining_substance_code_meaning" IS NOT NULL
GROUP BY
    "embedding_medium_code_meaning",
    "staining_substance_code_meaning"
ORDER BY
    "occurrence_count" DESC NULLS LAST,
    "embedding_medium_code_meaning",
    "staining_substance_code_meaning";