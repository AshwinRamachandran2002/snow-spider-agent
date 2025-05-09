WITH patient_avg AS (
    SELECT
        g."ParticipantBarcode"                                   AS patient_id,
        AVG(LOG(10, g."normalized_count" + 1))                  AS avg_log10_expr
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" g
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
          ON g."ParticipantBarcode" = c."bcr_patient_barcode"
    WHERE c."acronym" = 'LGG'
      AND g."Symbol"  = 'IGF2'
    GROUP BY g."ParticipantBarcode"
),
histology_avg AS (
    SELECT
        c."icd_o_3_histology",
        AVG(p.avg_log10_expr) AS avg_patient_log10_expr
    FROM patient_avg p
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
          ON p.patient_id = c."bcr_patient_barcode"
    WHERE c."icd_o_3_histology" NOT ILIKE '%[%'
    GROUP BY c."icd_o_3_histology"
)
SELECT
    "icd_o_3_histology",
    ROUND(avg_patient_log10_expr, 4) AS avg_patient_log10_expr
FROM histology_avg
ORDER BY avg_patient_log10_expr DESC NULLS LAST, "icd_o_3_histology";