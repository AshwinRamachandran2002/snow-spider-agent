WITH igf2_patient_avg AS (  -- per‑patient mean log10( IGF2 expression + 1 )
    SELECT
        "ParticipantBarcode"                      AS patient_barcode,
        AVG( LOG(10, "normalized_count" + 1) )    AS avg_log10_expr   -- LOG(base, value)
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Symbol" = 'IGF2'
    GROUP BY "ParticipantBarcode"
),
lgg_clin AS (  -- LGG clinical records with usable histology codes
    SELECT
        "bcr_patient_barcode"  AS patient_barcode,
        "icd_o_3_histology"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
    WHERE "acronym" = 'LGG'
      AND "icd_o_3_histology" IS NOT NULL
      AND "icd_o_3_histology" NOT LIKE '[%'      -- exclude bracketed values
)
SELECT
    c."icd_o_3_histology",
    AVG(p.avg_log10_expr) AS avg_patient_avg_log10_expr
FROM lgg_clin         AS c
JOIN igf2_patient_avg AS p
  ON c.patient_barcode = p.patient_barcode
GROUP BY c."icd_o_3_histology"
ORDER BY c."icd_o_3_histology";