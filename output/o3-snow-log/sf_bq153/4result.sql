WITH igf2_per_patient AS (
    SELECT
        g."ParticipantBarcode"                                    AS "ParticipantBarcode",
        AVG( LOG(10, g."normalized_count" + 1) )                  AS "patient_avg_log10_IGF2"
    FROM
        PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" g
    WHERE
        g."Study" = 'LGG'                 -- keep only LGG samples
        AND g."Symbol" = 'IGF2'           -- IGF2 gene
        AND g."normalized_count" IS NOT NULL
    GROUP BY
        g."ParticipantBarcode"
)

SELECT
    c."icd_o_3_histology"                                   AS "icd_o_3_histology",
    AVG(p."patient_avg_log10_IGF2")                         AS "avg_patient_avg_log10_IGF2_expr"
FROM
    igf2_per_patient p
JOIN
    PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
        ON p."ParticipantBarcode" = c."bcr_patient_barcode"
WHERE
    c."acronym" = 'LGG'                       -- LGG cohort
    AND c."icd_o_3_histology" IS NOT NULL
    AND c."icd_o_3_histology" NOT LIKE '[%'   -- exclude bracketed values
GROUP BY
    c."icd_o_3_histology"
ORDER BY
    "avg_patient_avg_log10_IGF2_expr" DESC NULLS LAST;