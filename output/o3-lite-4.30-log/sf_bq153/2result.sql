WITH per_patient_expr AS (
    SELECT
        "ParticipantBarcode"                                   AS participant_id,
        AVG(LOG(10, "normalized_count" + 1))                  AS avg_log10_expr
    FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Study" = 'LGG'
      AND "Symbol" = 'IGF2'
      AND "normalized_count" IS NOT NULL
    GROUP BY "ParticipantBarcode"
)

SELECT
    c."icd_o_3_histology"                                     AS icd_o_3_histology,
    ROUND(AVG(p.avg_log10_expr), 4)                           AS avg_patient_log10_expr
FROM per_patient_expr p
JOIN "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
  ON p.participant_id = c."bcr_patient_barcode"
WHERE c."acronym" = 'LGG'
  AND c."icd_o_3_histology" NOT LIKE '%[%'
GROUP BY c."icd_o_3_histology"
ORDER BY avg_patient_log10_expr DESC NULLS LAST;