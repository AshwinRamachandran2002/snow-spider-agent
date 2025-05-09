WITH lgg_clinical AS (
    -- LGG patients with valid (non-bracketed) histology codes
    SELECT
        "bcr_patient_barcode"        AS patient_barcode,
        "icd_o_3_histology"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
    WHERE "acronym" = 'LGG'
      AND "icd_o_3_histology" IS NOT NULL
      AND "icd_o_3_histology" NOT ILIKE '[%'          -- exclude bracketed values
),
igf2_expression AS (
    -- All IGF2 mRNA-seq rows (log10-transformed)
    SELECT
        "ParticipantBarcode"         AS patient_barcode,
        LOG(10, "normalized_count" + 1) AS log10_expr
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Symbol" = 'IGF2'
),
patient_level_avg AS (
    -- Per-patient average log10(IGF2) (LGG only)
    SELECT
        e.patient_barcode,
        AVG(e.log10_expr)            AS avg_log10_IGF2
    FROM igf2_expression e
    JOIN lgg_clinical    c ON e.patient_barcode = c.patient_barcode
    GROUP BY e.patient_barcode
)

-- Final: mean of per-patient averages for each histology code
SELECT
    c."icd_o_3_histology",
    AVG(p.avg_log10_IGF2) AS mean_patient_avg_log10_IGF2
FROM patient_level_avg p
JOIN lgg_clinical     c ON p.patient_barcode = c.patient_barcode
GROUP BY c."icd_o_3_histology"
ORDER BY c."icd_o_3_histology";