WITH patient_igf2 AS (
    /* Compute per‑patient mean log10(IGF2 normalized_count + 1) */
    SELECT
        "ParticipantBarcode",
        AVG( LOG("normalized_count" + 1, 10) ) AS patient_avg_log10_expr
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Symbol" = 'IGF2'
      AND "normalized_count" IS NOT NULL
    GROUP BY "ParticipantBarcode"
)

SELECT
    c."icd_o_3_histology"                          AS "icd_o_3_histology",
    ROUND( AVG(p.patient_avg_log10_expr), 4 )      AS "avg_patient_avg_log10_igf2_expr"
FROM patient_igf2  p
JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED  c
      ON p."ParticipantBarcode" = c."bcr_patient_barcode"
WHERE c."acronym" = 'LGG'                          -- LGG patients only
  AND c."icd_o_3_histology" IS NOT NULL            -- valid histology
  AND c."icd_o_3_histology" NOT LIKE '[%'          -- exclude values in square brackets
GROUP BY c."icd_o_3_histology"
ORDER BY c."icd_o_3_histology";