/*  IGF2 expression (log10-transformed) summarized per histology for LGG  */
WITH per_patient_igf2 AS (
    /* 1.  Patient-level mean of log10(normalized_count + 1) for IGF2  */
    SELECT
        g."ParticipantBarcode",
        AVG( LOG( g."normalized_count" + 1 , 10) )   AS "avg_log10_IGF2"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" g
    WHERE  g."Study"  = 'LGG'
      AND  g."Symbol" = 'IGF2'
    GROUP  BY g."ParticipantBarcode"
)

SELECT
    c."icd_o_3_histology"                               AS "icd_o_3_histology",
    COUNT( DISTINCT p."ParticipantBarcode")             AS "n_patients",
    AVG( p."avg_log10_IGF2" )                           AS "mean_avg_log10_IGF2"
FROM   per_patient_igf2               p
JOIN   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
       ON p."ParticipantBarcode" = c."bcr_patient_barcode"
WHERE  c."acronym" = 'LGG'
  AND  c."icd_o_3_histology" IS NOT NULL
  AND  c."icd_o_3_histology" NOT ILIKE '[%'            -- exclude bracketed values
GROUP  BY c."icd_o_3_histology"
ORDER  BY "mean_avg_log10_IGF2" DESC NULLS LAST;