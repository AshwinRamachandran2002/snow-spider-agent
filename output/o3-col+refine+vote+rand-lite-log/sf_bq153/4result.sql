WITH patient_means AS (
    SELECT
        e."ParticipantBarcode",
        AVG(LOG(e."normalized_count" + 1, 10)) AS "patient_mean_log10_IGF2"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
    WHERE e."Study" = 'LGG'
      AND e."Symbol" = 'IGF2'
    GROUP BY e."ParticipantBarcode"
)

SELECT
    c."icd_o_3_histology",
    AVG(pm."patient_mean_log10_IGF2") AS "histology_avg_patient_IGF2"
FROM patient_means pm
JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
      ON pm."ParticipantBarcode" = c."bcr_patient_barcode"
WHERE c."acronym" = 'LGG'
  AND c."icd_o_3_histology" NOT LIKE '[%'   -- exclude bracketed codes
GROUP BY c."icd_o_3_histology"
ORDER BY "histology_avg_patient_IGF2" DESC NULLS LAST;