WITH igf2_per_patient AS (
    SELECT
        "ParticipantBarcode",
        AVG( LOG("normalized_count" + 1 , 10) ) AS "patient_avg_log10_expr"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'IGF2'
      AND "normalized_count" IS NOT NULL
    GROUP BY "ParticipantBarcode"
),
clinical_lgg AS (
    SELECT
        "bcr_patient_barcode" AS "ParticipantBarcode",
        "icd_o_3_histology"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "icd_o_3_histology" IS NOT NULL
)
SELECT
    c."icd_o_3_histology"                              AS "icd_o_3_histology",
    ROUND( AVG(p."patient_avg_log10_expr"), 4 )        AS "avg_patient_log10_expr"
FROM igf2_per_patient p
JOIN clinical_lgg     c
  ON p."ParticipantBarcode" = c."ParticipantBarcode"
WHERE c."icd_o_3_histology" NOT LIKE '%[%'
GROUP BY c."icd_o_3_histology"
ORDER BY "avg_patient_log10_expr" DESC NULLS LAST;