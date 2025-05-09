/*  Average of per-patient mean log10(IGF2 expression+1) for each LGG histology code */
WITH patient_avg AS (
    SELECT
        g."ParticipantBarcode",
        AVG( LOG(10, g."normalized_count" + 1) ) AS "avg_log10_IGF2"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"  g
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"            c
      ON g."ParticipantBarcode" = c."bcr_patient_barcode"
    WHERE g."Symbol"      = 'IGF2'
      AND c."acronym"     = 'LGG'
      AND c."icd_o_3_histology" IS NOT NULL
      AND c."icd_o_3_histology" NOT ILIKE '[%'      -- exclude placeholder codes
    GROUP BY g."ParticipantBarcode"
)

SELECT
    c."icd_o_3_histology"                       AS "histology_code",
    AVG(pa."avg_log10_IGF2")                    AS "mean_patient_avg_log10_IGF2"
FROM patient_avg                pa
JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"  c
  ON pa."ParticipantBarcode" = c."bcr_patient_barcode"
GROUP BY c."icd_o_3_histology"
ORDER BY "mean_patient_avg_log10_IGF2" DESC NULLS LAST;