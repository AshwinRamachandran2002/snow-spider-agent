WITH lgg_patients AS (
    SELECT
        "bcr_patient_barcode"  AS patient_barcode,
        "icd_o_3_histology"    AS histology
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'LGG'
      AND "icd_o_3_histology" IS NOT NULL
      AND "icd_o_3_histology" NOT LIKE '[%'          -- exclude bracketed codes
),
igf2_expression AS (
    SELECT
        "ParticipantBarcode"   AS patient_barcode,
        LOG("normalized_count" + 1, 10) AS log_expr  -- base-10 log
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'IGF2'
      AND "normalized_count" IS NOT NULL
),
patient_level_avg AS (
    SELECT
        patient_barcode,
        AVG(log_expr)          AS patient_avg_log_expr
    FROM igf2_expression
    GROUP BY patient_barcode
),
joined AS (
    SELECT
        lp.histology,
        pla.patient_avg_log_expr
    FROM patient_level_avg pla
    JOIN lgg_patients  lp
      ON pla.patient_barcode = lp.patient_barcode
)
SELECT
    histology,
    AVG(patient_avg_log_expr) AS avg_log10_normalized_count_plus1_igf2
FROM joined
GROUP BY histology
ORDER BY avg_log10_normalized_count_plus1_igf2 DESC NULLS LAST;