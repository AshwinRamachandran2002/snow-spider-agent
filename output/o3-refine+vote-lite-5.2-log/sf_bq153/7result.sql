WITH igf2_per_patient AS (
    /* Per-patient mean base‑10 log expression of IGF2 */
    SELECT
        "ParticipantBarcode"                                     AS patient_barcode,
        AVG( LOG("normalized_count" + 1, 10) )                   AS avg_log10_igf2
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE
        "Symbol" = 'IGF2'
        AND "normalized_count" IS NOT NULL
    GROUP BY
        "ParticipantBarcode"
),
lgg_clinical AS (
    /* LGG patients with valid (non‑bracketed) histology codes */
    SELECT
        "bcr_patient_barcode" AS patient_barcode,
        "icd_o_3_histology"   AS histology
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
    WHERE
        "acronym" = 'LGG'
        AND "icd_o_3_histology" IS NOT NULL
        AND "icd_o_3_histology" NOT LIKE '[%'          -- exclude entries wrapped in brackets
)
SELECT
    c.histology                           AS "icd_o_3_histology",
    AVG(p.avg_log10_igf2)                 AS "avg_patient_mean_log10_IGF2_expr"
FROM lgg_clinical c
JOIN igf2_per_patient p
      ON c.patient_barcode = p.patient_barcode
GROUP BY
    c.histology
ORDER BY
    "avg_patient_mean_log10_IGF2_expr" DESC NULLS LAST;