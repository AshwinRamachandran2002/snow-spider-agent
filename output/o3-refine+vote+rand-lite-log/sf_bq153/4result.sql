WITH igf2_patient_avg AS (  -- per‑patient mean log10(expr+1) for IGF2
    SELECT
        "ParticipantBarcode"                                                       AS "ParticipantBarcode",
        AVG( LOG(10, "normalized_count" + 1) )                                     AS "patient_avg_log10_expr"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Study" = 'LGG'              -- limit to LGG cohort
      AND "Symbol" = 'IGF2'            -- IGF2 gene only
      AND "normalized_count" IS NOT NULL
    GROUP BY "ParticipantBarcode"
),

lgg_clin AS (        -- LGG clinical data with valid histology codes
    SELECT
        "bcr_patient_barcode"  AS "ParticipantBarcode",
        "icd_o_3_histology"    AS "icd_o_3_histology"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
    WHERE "acronym" = 'LGG'
      AND "icd_o_3_histology" IS NOT NULL
      AND "icd_o_3_histology" NOT ILIKE '%[%'   -- exclude codes enclosed in brackets
)

SELECT
    c."icd_o_3_histology",
    AVG(p."patient_avg_log10_expr") AS "avg_patient_avg_log10_expr"
FROM lgg_clin c
JOIN igf2_patient_avg p
  ON c."ParticipantBarcode" = p."ParticipantBarcode"
GROUP BY c."icd_o_3_histology"
ORDER BY c."icd_o_3_histology";