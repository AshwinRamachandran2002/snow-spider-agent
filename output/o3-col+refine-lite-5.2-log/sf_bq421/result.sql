-- List embedding‑medium / staining‑substance SCT code‑meaning pairs
-- observed in SM‑modality images, together with their occurrence counts
WITH prep_items AS (
    SELECT
        t."SOPInstanceUID",
        LOWER(
            g.value:"ConceptNameCodeSequence"[0]:"CodeMeaning"::STRING
        )                                          AS concept_name,
        g.value:"ConceptCodeSequence"[0]:"CodeMeaning"::STRING
                                                   AS code_meaning
    FROM IDC.IDC_V17."DICOM_ALL" t
         , LATERAL FLATTEN( INPUT => t."SpecimenDescriptionSequence")                                       f
         , LATERAL FLATTEN( INPUT => f.value:"SpecimenPreparationSequence",               OUTER => TRUE )   p
         , LATERAL FLATTEN( INPUT => p.value:"SpecimenPreparationStepContentItemSequence", OUTER => TRUE )  g
    WHERE t."Modality" = 'SM'                                          -- only SM modality
      AND g.value IS NOT NULL
      AND g.value:"ConceptCodeSequence"[0]:"CodingSchemeDesignator"::STRING = 'SCT'   -- SCT codes
      AND LOWER(g.value:"ConceptNameCodeSequence"[0]:"CodeMeaning"::STRING)
          IN ('embedding medium','using substance')                   -- items of interest
),
embedding AS (    -- embedding‑medium items
    SELECT DISTINCT
           "SOPInstanceUID",
           code_meaning AS embedding_medium
    FROM prep_items
    WHERE concept_name = 'embedding medium'
),
staining AS (     -- staining‑substance items
    SELECT DISTINCT
           "SOPInstanceUID",
           code_meaning AS staining_substance
    FROM prep_items
    WHERE concept_name = 'using substance'
)
SELECT
    emb.embedding_medium       AS "EmbeddingMedium_CodeMeaning",
    stn.staining_substance     AS "StainingSubstance_CodeMeaning",
    COUNT(DISTINCT emb."SOPInstanceUID") AS "Pair_Occurrences"
FROM embedding emb
JOIN staining  stn
  ON emb."SOPInstanceUID" = stn."SOPInstanceUID"
GROUP BY
    emb.embedding_medium,
    stn.staining_substance
ORDER BY
    "Pair_Occurrences" DESC NULLS LAST,
    "EmbeddingMedium_CodeMeaning",
    "StainingSubstance_CodeMeaning";