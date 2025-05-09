WITH lgg_patients AS (
    SELECT
        "bcr_patient_barcode"   AS patient_barcode,
        "icd_o_3_histology"     AS histology
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE
        "acronym" = 'LGG'
        AND "icd_o_3_histology" IS NOT NULL
        AND "icd_o_3_histology" NOT LIKE '[%'            -- exclude bracketed values
),
igf2_expression AS (
    SELECT
        "ParticipantBarcode"    AS patient_barcode,
        LOG(10, "normalized_count" + 1)  AS log_expr     -- base-10 logarithm
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE
        "Symbol" = 'IGF2'
        AND "normalized_count" IS NOT NULL
),
per_patient_avg AS (
    SELECT
        p.histology,
        e.patient_barcode,
        AVG(e.log_expr) AS avg_log_expr                  -- per-patient mean
    FROM igf2_expression e
    JOIN lgg_patients   p
      ON p.patient_barcode = e.patient_barcode
    GROUP BY p.histology, e.patient_barcode
)
SELECT
    histology                          AS "icd_o_3_histology",
    AVG(avg_log_expr)                  AS "avg_patient_avg_log10_expr"
FROM per_patient_avg
GROUP BY histology
ORDER BY "avg_patient_avg_log10_expr" DESC NULLS LAST;