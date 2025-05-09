WITH patient_expr AS (
    /* 1)  Per-patient mean log10(IGF2 expression + 1) */
    SELECT
        "ParticipantBarcode"                                   AS "patient_barcode",
        AVG( LOG(10, "normalized_count" + 1) )                 AS "patient_avg_expr"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'IGF2'
      AND "normalized_count" IS NOT NULL
    GROUP BY "ParticipantBarcode"
),
lgg_clin AS (
    /* 2)  LGG clinical records with valid (non-bracketed) histology codes */
    SELECT
        "bcr_patient_barcode"  AS "patient_barcode",
        "icd_o_3_histology"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
    WHERE "acronym" = 'LGG'
      AND "icd_o_3_histology" IS NOT NULL
      AND "icd_o_3_histology" NOT LIKE '%[%'
)
/* 3)  Histology-level mean of the per-patient averages */
SELECT
    lc."icd_o_3_histology"                              AS "histology_type",
    ROUND(AVG(pe."patient_avg_expr"), 4)                AS "avg_log10_expr"
FROM lgg_clin lc
JOIN patient_expr pe
  ON lc."patient_barcode" = pe."patient_barcode"
GROUP BY lc."icd_o_3_histology"
ORDER BY "avg_log10_expr" DESC NULLS LAST;