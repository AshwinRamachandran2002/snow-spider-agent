WITH lgg_clinical AS (
    SELECT
        "bcr_patient_barcode"      AS participant_barcode,
        "icd_o_3_histology"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'LGG'
      AND "icd_o_3_histology" IS NOT NULL
      AND "icd_o_3_histology" NOT LIKE '[%'          -- exclude bracketed values
),
igf2_expression AS (
    SELECT
        "ParticipantBarcode"       AS participant_barcode,
        LOG(10, "normalized_count" + 1) AS log_expr  -- base‑10 log
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Symbol" = 'IGF2'
      AND "normalized_count" IS NOT NULL
),
per_patient_avg AS (
    SELECT
        participant_barcode,
        AVG(log_expr)              AS avg_log_expr
    FROM igf2_expression
    GROUP BY participant_barcode
)
SELECT
    lc."icd_o_3_histology",
    AVG(pa.avg_log_expr)           AS avg_patient_avg_log10_expr
FROM lgg_clinical lc
JOIN per_patient_avg pa
  ON lc.participant_barcode = pa.participant_barcode
GROUP BY lc."icd_o_3_histology"
ORDER BY avg_patient_avg_log10_expr DESC NULLS LAST,
         lc."icd_o_3_histology";