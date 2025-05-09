WITH prep_items AS (
    SELECT
        t."SOPInstanceUID"                                            AS instance_uid,
        itm.value:"ConceptNameCodeSequence"[0]:"CodeMeaning"        ::STRING AS concept_name,
        itm.value:"ConceptCodeSequence"[0]:"CodeMeaning"            ::STRING AS code_meaning,
        itm.value:"ConceptCodeSequence"[0]:"CodingSchemeDesignator" ::STRING AS code_scheme
    FROM   "IDC"."IDC_V17"."DICOM_METADATA" t
           ,LATERAL FLATTEN(input => t."SpecimenDescriptionSequence")                        desc_obj
           ,LATERAL FLATTEN(input => desc_obj.value:"SpecimenPreparationSequence")           seq
           ,LATERAL FLATTEN(input => seq.value:"SpecimenPreparationStepContentItemSequence") itm
    WHERE  t."Modality" = 'SM'
),
emb AS (   -- embedding medium per instance
    SELECT DISTINCT
           instance_uid,
           code_meaning AS embedding_medium
    FROM   prep_items
    WHERE  code_scheme = 'SCT'
      AND  concept_name ILIKE '%embedding%medium%'
      AND  code_meaning IS NOT NULL
),
stain AS ( -- staining substance per instance
    SELECT DISTINCT
           instance_uid,
           code_meaning AS staining_substance
    FROM   prep_items
    WHERE  code_scheme = 'SCT'
      AND (concept_name ILIKE '%using%substance%'
           OR concept_name ILIKE '%staining%substance%')
      AND  code_meaning IS NOT NULL
)
SELECT
    emb.embedding_medium     AS embedding_medium_code_meaning,
    stain.staining_substance AS staining_substance_code_meaning,
    COUNT(DISTINCT emb.instance_uid) AS occurrence_count
FROM   emb
JOIN   stain
  ON   emb.instance_uid = stain.instance_uid
GROUP BY 1, 2
ORDER BY occurrence_count DESC NULLS LAST,
         embedding_medium_code_meaning,
         staining_substance_code_meaning;