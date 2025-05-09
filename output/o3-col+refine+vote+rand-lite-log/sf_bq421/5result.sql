WITH embedding AS (   -- embedding-medium code meanings per SM image
    SELECT DISTINCT
           t."SOPInstanceUID",
           cc.value:"CodeMeaning"::STRING               AS embed_meaning
    FROM IDC.IDC_V17.DICOM_METADATA t,
         LATERAL FLATTEN (INPUT => t."SpecimenDescriptionSequence")                        sd ,
         LATERAL FLATTEN (INPUT => sd.value:"SpecimenPreparationSequence")                 prep ,
         LATERAL FLATTEN (INPUT => prep.value:"SpecimenPreparationStepContentItemSequence") ci ,
         LATERAL FLATTEN (INPUT => ci.value:"ConceptNameCodeSequence")                     cn ,
         LATERAL FLATTEN (INPUT => ci.value:"ConceptCodeSequence")                         cc
    WHERE t."Modality" = 'SM'
      AND cn.value:"CodeMeaning"::STRING = 'Embedding medium'          -- the step we want
      AND cc.value:"CodingSchemeDesignator"::STRING = 'SCT'            -- use only SCT codes
),
staining AS (    -- staining-substance code meanings per SM image
    SELECT DISTINCT
           t."SOPInstanceUID",
           cc.value:"CodeMeaning"::STRING               AS stain_meaning
    FROM IDC.IDC_V17.DICOM_METADATA t,
         LATERAL FLATTEN (INPUT => t."SpecimenDescriptionSequence")                        sd ,
         LATERAL FLATTEN (INPUT => sd.value:"SpecimenPreparationSequence")                 prep ,
         LATERAL FLATTEN (INPUT => prep.value:"SpecimenPreparationStepContentItemSequence") ci ,
         LATERAL FLATTEN (INPUT => ci.value:"ConceptNameCodeSequence")                     cn ,
         LATERAL FLATTEN (INPUT => ci.value:"ConceptCodeSequence")                         cc
    WHERE t."Modality" = 'SM'
      AND cn.value:"CodeMeaning"::STRING = 'Using substance'          -- identifies substance used
      AND cc.value:"CodingSchemeDesignator"::STRING = 'SCT'           -- use only SCT codes
      AND LOWER(cc.value:"CodeMeaning"::STRING) LIKE '%stain%'        -- keep staining substances
)
SELECT
       e.embed_meaning                                   AS "Embedding_Medium_CodeMeaning",
       s.stain_meaning                                   AS "Staining_Substance_CodeMeaning",
       COUNT(DISTINCT e."SOPInstanceUID")                AS "NumImages"
FROM   embedding e
JOIN   staining  s
       ON e."SOPInstanceUID" = s."SOPInstanceUID"
GROUP BY
       e.embed_meaning,
       s.stain_meaning
ORDER BY
       "NumImages" DESC NULLS LAST;