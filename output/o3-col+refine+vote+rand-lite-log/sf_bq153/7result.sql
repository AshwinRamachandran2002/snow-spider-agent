WITH per_patient AS (
    /* -----------------------------------------------------------
       For each LGG participant, average log10(IGF2 normalized_count + 1)
       across all of that participant’s RNA-seq samples
    ------------------------------------------------------------ */
    SELECT
        g."ParticipantBarcode",
        AVG( LOG(10, g."normalized_count" + 1) ) AS "patient_mean_log10_IGF2"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED g
    WHERE g."Symbol" = 'IGF2'
      AND g."Study"  = 'LGG'
    GROUP BY g."ParticipantBarcode"
)
/* -----------------------------------------------------------------
   Join to clinical data, keep LGG cases, drop bracketed histology
   codes, then compute the requested aggregate per histology type
------------------------------------------------------------------ */
SELECT
    c."icd_o_3_histology"                       AS "icd_o_3_histology",
    AVG( p."patient_mean_log10_IGF2" )          AS "avg_patient_mean_log10_IGF2",
    COUNT(*)                                    AS "n_patients"
FROM per_patient p
JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED c
  ON p."ParticipantBarcode" = c."bcr_patient_barcode"
WHERE c."acronym" = 'LGG'
  AND c."icd_o_3_histology" IS NOT NULL
  AND c."icd_o_3_histology" NOT LIKE '%[%'      -- exclude bracketed entries
GROUP BY c."icd_o_3_histology"
ORDER BY "avg_patient_mean_log10_IGF2" DESC NULLS LAST;