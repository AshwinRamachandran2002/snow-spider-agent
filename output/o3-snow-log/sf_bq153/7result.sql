/*  Average per-histology IGF2 expression (log10(normalized_count+1)) for LGG patients  */
WITH patient_igf2_expression AS (
    /* Per-patient mean log10 expression of IGF2 across all samples */
    SELECT
        ge."ParticipantBarcode"                                     AS participant_barcode,
        AVG( LOG(10, ge."normalized_count" + 1) )                   AS patient_avg_log_expr
    FROM
        "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"  ge
    WHERE
        ge."Symbol" = 'IGF2'
        AND ge."normalized_count" IS NOT NULL
    GROUP BY
        ge."ParticipantBarcode"
)
SELECT
    cl."icd_o_3_histology"                                          AS icd_o_3_histology,
    AVG(pe.patient_avg_log_expr)                                    AS avg_patient_avg_log_expr
FROM
    patient_igf2_expression               pe
JOIN
    "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"  cl
        ON cl."bcr_patient_barcode" = pe.participant_barcode
WHERE
    cl."acronym" = 'LGG'                      -- restrict to LGG cohort
    AND cl."icd_o_3_histology" IS NOT NULL
    AND cl."icd_o_3_histology" NOT LIKE '[%'  -- exclude bracketed histology values
GROUP BY
    cl."icd_o_3_histology"
ORDER BY
    avg_patient_avg_log_expr DESC NULLS LAST;