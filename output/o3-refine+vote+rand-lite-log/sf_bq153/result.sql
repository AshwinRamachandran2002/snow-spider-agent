WITH igf2_per_sample AS (
    SELECT
        "ParticipantBarcode",
        LOG(10, "normalized_count" + 1) AS log10_expr   -- log10 transformation
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'IGF2'
      AND "normalized_count" IS NOT NULL
),
igf2_per_patient AS (
    SELECT
        "ParticipantBarcode",
        AVG(log10_expr) AS avg_log10_expr               -- per‑patient average
    FROM igf2_per_sample
    GROUP BY "ParticipantBarcode"
)
SELECT
    clin."icd_o_3_histology",
    ROUND(AVG(pt.avg_log10_expr), 4) AS avg_patient_avg_log10_expr
FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED AS clin
JOIN igf2_per_patient AS pt
  ON clin."bcr_patient_barcode" = pt."ParticipantBarcode"
WHERE clin."icd_o_3_histology" IS NOT NULL
  AND clin."icd_o_3_histology" NOT LIKE '[%'           -- exclude bracketed values
GROUP BY clin."icd_o_3_histology"
ORDER BY clin."icd_o_3_histology";