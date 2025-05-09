WITH igf2_expression AS (
    -- IGF2 expression for LGG samples
    SELECT
        "ParticipantBarcode",
        LOG(10, "normalized_count" + 1)                       AS "log_expr"   -- log10
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Symbol" = 'IGF2'
      AND "Study"  = 'LGG'
      AND "normalized_count" IS NOT NULL
),
per_patient_avg AS (
    -- average log‑expression per LGG patient
    SELECT
        "ParticipantBarcode",
        AVG("log_expr")                                       AS "avg_log_expr"
    FROM igf2_expression
    GROUP BY "ParticipantBarcode"
),
joined_clinical AS (
    -- attach clinical info and keep valid histology codes
    SELECT
        c."icd_o_3_histology"                                AS "histology",
        p."avg_log_expr"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED c
    JOIN per_patient_avg p
      ON p."ParticipantBarcode" = c."bcr_patient_barcode"
    WHERE c."acronym" = 'LGG'
      AND c."icd_o_3_histology" IS NOT NULL
      AND c."icd_o_3_histology" NOT LIKE '[%'                -- exclude bracketed values
)
-- average of per‑patient averages, grouped by histology
SELECT
    "histology",
    AVG("avg_log_expr") AS "mean_patient_avg_log10_expr"
FROM joined_clinical
GROUP BY "histology"
ORDER BY "histology";