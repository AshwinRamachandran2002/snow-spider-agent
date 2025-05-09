WITH per_patient AS (
    /*--- average IGF2 expression (log10 scale) for each LGG patient ---*/
    SELECT
        c."bcr_patient_barcode"                   AS "patient_barcode",
        c."icd_o_3_histology"                     AS "icd_o_3_histology",
        AVG( LOG(10, e."normalized_count" + 1) )  AS "avg_log10_IGF2"
    FROM
        PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"  AS c
    JOIN
        PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" AS e
      ON c."bcr_patient_barcode" = e."ParticipantBarcode"
    WHERE
        c."acronym"              = 'LGG'          -- restrict to LGG study
        AND e."Symbol"           = 'IGF2'         -- IGF2 gene only
        AND c."icd_o_3_histology" NOT LIKE '[%'   -- exclude bracketed (invalid) codes
    GROUP BY
        c."bcr_patient_barcode",
        c."icd_o_3_histology"
)

SELECT
    "icd_o_3_histology",
    AVG("avg_log10_IGF2")  AS "histology_mean_avg_log10_IGF2"
FROM
    per_patient
GROUP BY
    "icd_o_3_histology"
ORDER BY
    "histology_mean_avg_log10_IGF2" DESC NULLS LAST;