/*  Return every unique pair of SCT “Embedding medium” and “Staining substance”              */
/*  (the latter recorded under Concept Name either “Staining” or “Using substance”)          */
/*  found in Specimen-Preparation sequences of SM-modality instances, together with          */
/*  the number of SOP instances in which each pair occurs.                                   */

WITH embedding AS (        --  (instance , embedding-medium)
    SELECT  dm."SOPInstanceUID",
            cc.value:"CodeMeaning"::STRING AS "embedding_medium"
    FROM    IDC.IDC_V17.DICOM_METADATA  dm
            ,LATERAL FLATTEN(input => dm."SpecimenDescriptionSequence")                    s
            ,LATERAL FLATTEN(input => s.value:"SpecimenPreparationSequence")               prep
            ,LATERAL FLATTEN(input => prep.value:"SpecimenPreparationStepContentItemSequence") step
            ,LATERAL FLATTEN(input => step.value:"ConceptNameCodeSequence")                cn
            ,LATERAL FLATTEN(input => step.value:"ConceptCodeSequence")                    cc
    WHERE   dm."Modality" = 'SM'
      AND   cn.value:"CodingSchemeDesignator"::STRING = 'SCT'
      AND   cc.value:"CodingSchemeDesignator"::STRING = 'SCT'
      AND   cn.value:"CodeMeaning"::STRING ILIKE '%embedding%'
), 

staining AS (              --  (instance , staining-substance)
    SELECT  dm."SOPInstanceUID",
            cc.value:"CodeMeaning"::STRING AS "staining_substance"
    FROM    IDC.IDC_V17.DICOM_METADATA  dm
            ,LATERAL FLATTEN(input => dm."SpecimenDescriptionSequence")                    s
            ,LATERAL FLATTEN(input => s.value:"SpecimenPreparationSequence")               prep
            ,LATERAL FLATTEN(input => prep.value:"SpecimenPreparationStepContentItemSequence") step
            ,LATERAL FLATTEN(input => step.value:"ConceptNameCodeSequence")                cn
            ,LATERAL FLATTEN(input => step.value:"ConceptCodeSequence")                    cc
    WHERE   dm."Modality" = 'SM'
      AND   cn.value:"CodingSchemeDesignator"::STRING = 'SCT'
      AND   cc.value:"CodingSchemeDesignator"::STRING = 'SCT'
      AND  (cn.value:"CodeMeaning"::STRING ILIKE '%stain%' 
            OR cn.value:"CodeMeaning"::STRING ILIKE '%using substance%')
)

SELECT  emb."embedding_medium",
        st."staining_substance",
        COUNT(DISTINCT emb."SOPInstanceUID") AS "occurrences"
FROM    embedding  emb
JOIN    staining   st
       ON st."SOPInstanceUID" = emb."SOPInstanceUID"
GROUP BY emb."embedding_medium",
         st."staining_substance"
ORDER BY "occurrences" DESC NULLS LAST;