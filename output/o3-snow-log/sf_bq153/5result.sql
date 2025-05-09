WITH igf2_exp AS (                        -- all IGF2 expression measurements
    SELECT
        "ParticipantBarcode"                                  AS patient_barcode,
        LOG(10, "normalized_count" + 1)                       AS log_expr
    FROM
        PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE
        "Symbol" = 'IGF2'
        AND "normalized_count" IS NOT NULL
),
per_patient_avg AS (                   -- per-patient mean of log10(expr+1)
    SELECT
        e.patient_barcode,
        AVG(e.log_expr)                                   AS patient_mean_log_expr
    FROM
        igf2_exp e
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
          ON e.patient_barcode = c."bcr_patient_barcode"
    WHERE
        c."acronym" = 'LGG'                               -- LGG patients only
    GROUP BY
        e.patient_barcode
)
SELECT                                             -- histology-level averages
    c."icd_o_3_histology"                           AS histology,
    AVG(p.patient_mean_log_expr)                    AS avg_patient_avg_log10_expr
FROM
    per_patient_avg p
JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
      ON p.patient_barcode = c."bcr_patient_barcode"
WHERE
    c."icd_o_3_histology" IS NOT NULL
    AND c."icd_o_3_histology" NOT LIKE '[%'         -- exclude bracketed codes
GROUP BY
    c."icd_o_3_histology";