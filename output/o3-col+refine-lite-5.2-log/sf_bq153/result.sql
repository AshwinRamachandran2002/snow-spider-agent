WITH patient_log_igf2 AS (
    SELECT
        "ParticipantBarcode",
        AVG( LOG(10, "normalized_count" + 1) ) AS "avg_log10_IGF2_per_patient"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Symbol" = 'IGF2'
    GROUP BY "ParticipantBarcode"
)

SELECT
    c."icd_o_3_histology"                               AS "histology",
    AVG(p."avg_log10_IGF2_per_patient")                 AS "mean_patient_avg_log10_IGF2"
FROM patient_log_igf2 p
JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
      ON p."ParticipantBarcode" = c."bcr_patient_barcode"
WHERE c."acronym" = 'LGG'
  AND c."icd_o_3_histology" IS NOT NULL
  AND c."icd_o_3_histology" NOT ILIKE '%[%'
GROUP BY c."icd_o_3_histology"
ORDER BY "mean_patient_avg_log10_IGF2" DESC NULLS LAST;