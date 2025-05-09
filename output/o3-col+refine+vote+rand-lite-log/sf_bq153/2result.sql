WITH patient_level AS (
    /*-- 1.  Per-patient mean log10(IGF2 + 1) expression ----------------------*/
    SELECT
        g."ParticipantBarcode",
        AVG( LOG(10, g."normalized_count" + 1) )  AS "avg_log10_IGF2"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" g
    WHERE g."Study"  = 'LGG'          -- LGG cohort only
      AND g."Symbol" = 'IGF2'         -- IGF2 gene
      AND g."normalized_count" IS NOT NULL
    GROUP BY g."ParticipantBarcode"
),
clinical_lgg AS (
    /*-- 2.  LGG clinical records with usable histology codes ------------------*/
    SELECT
        c."bcr_patient_barcode"  AS "ParticipantBarcode",
        c."icd_o_3_histology"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
    WHERE c."acronym" = 'LGG'
      AND c."icd_o_3_histology" IS NOT NULL
      AND c."icd_o_3_histology" NOT ILIKE '%[%'   -- drop bracketed codes
)
SELECT
    cl."icd_o_3_histology"                         AS "histology_code",
    AVG(pl."avg_log10_IGF2")                      AS "mean_patient_avg_log10_IGF2"
FROM patient_level  pl
JOIN clinical_lgg   cl
  ON pl."ParticipantBarcode" = cl."ParticipantBarcode"
GROUP BY cl."icd_o_3_histology"
ORDER BY "mean_patient_avg_log10_IGF2" DESC NULLS LAST;