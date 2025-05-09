SELECT cl."histological_type",
       ROUND(AVG(LOG(10, ge."normalized_count" + 1)), 4) AS "average_log10_normalized_expression"
FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" ge
JOIN "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" cl
  ON ge."ParticipantBarcode" = cl."bcr_patient_barcode"
WHERE ge."Symbol" = 'IGF2'
  AND ge."normalized_count" IS NOT NULL
  AND cl."acronym" = 'LGG'
  AND cl."histological_type" IS NOT NULL
  AND NOT REGEXP_LIKE(cl."histological_type", '^\\[.*\\]$')
GROUP BY cl."histological_type"
ORDER BY cl."histological_type";