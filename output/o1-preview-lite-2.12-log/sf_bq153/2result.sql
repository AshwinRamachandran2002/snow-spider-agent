SELECT c."histological_type",
       ROUND(AVG(LN(e."normalized_count" + 1) / LN(10)), 4) AS average_log10_normalized_expression
FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED AS e
JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED AS c
  ON e."ParticipantBarcode" = c."bcr_patient_barcode"
WHERE e."Symbol" = 'IGF2'
  AND e."normalized_count" IS NOT NULL
  AND c."acronym" = 'LGG'
  AND NOT REGEXP_LIKE(c."histological_type", '^\\[.*\\]$')
GROUP BY c."histological_type";