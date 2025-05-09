WITH expr AS (
    SELECT
        "ParticipantBarcode",
        LOG(10, "normalized_count" + 1) AS log_expr          -- log10(normalized_count + 1)
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Symbol" = 'IGF2'
      AND "Study"  = 'LGG'                                   -- keep only LGG samples
      AND "normalized_count" IS NOT NULL
),
patient_avg AS (                                              -- per-patient mean expression
    SELECT
        "ParticipantBarcode",
        AVG(log_expr) AS avg_log_expr
    FROM expr
    GROUP BY "ParticipantBarcode"
)
SELECT
    c."icd_o_3_histology",
    AVG(p.avg_log_expr) AS avg_log10_igf2_expression
FROM patient_avg                p
JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED  c
      ON p."ParticipantBarcode" = c."bcr_patient_barcode"
WHERE c."acronym" = 'LGG'                                     -- LGG clinical records
  AND c."icd_o_3_histology" IS NOT NULL
  AND c."icd_o_3_histology" NOT LIKE '%[%'                    -- exclude values in brackets
GROUP BY c."icd_o_3_histology"
ORDER BY avg_log10_igf2_expression DESC NULLS LAST;