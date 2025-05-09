WITH per_patient AS (
    /* Mean log10(IGF2 normalized_count + 1) for each participant */
    SELECT
        "ParticipantBarcode",
        AVG(LOG(10, "normalized_count" + 1)) AS patient_avg_log10_expr
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Symbol" = 'IGF2'
      AND "normalized_count" IS NOT NULL
    GROUP BY "ParticipantBarcode"
)

SELECT
    c."icd_o_3_histology",
    ROUND(AVG(p.patient_avg_log10_expr), 4) AS avg_patient_log10_expr
FROM per_patient p
JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
  ON p."ParticipantBarcode" = c."bcr_patient_barcode"
WHERE c."acronym" = 'LGG'
  AND c."icd_o_3_histology" IS NOT NULL
  AND c."icd_o_3_histology" NOT LIKE '%[%'
GROUP BY c."icd_o_3_histology"
ORDER BY avg_patient_log10_expr DESC NULLS LAST,
         c."icd_o_3_histology";