WITH igf2_expr AS (  -- IGF2 expression values
    SELECT
        "ParticipantBarcode"               AS patient_id,
        LOG(10, "normalized_count" + 1)    AS log10_expr  -- log base 10
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
    WHERE "Symbol" = 'IGF2'
      AND "normalized_count" IS NOT NULL
),                                                      
per_patient_mean AS (    -- average IGF2 expression per patient
    SELECT
        patient_id,
        AVG(log10_expr) AS mean_log10_expr
    FROM igf2_expr
    GROUP BY patient_id
),                                                      
lgg_clinical AS (        -- LGG clinical data with valid histology codes
    SELECT
        "bcr_patient_barcode" AS patient_id,
        "icd_o_3_histology"   AS histology_code
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
    WHERE "acronym" = 'LGG'
      AND "icd_o_3_histology" IS NOT NULL
      AND "icd_o_3_histology" NOT LIKE '%[%'
)                                                      
SELECT
    lc.histology_code                       AS "icd_o_3_histology",
    AVG(pp.mean_log10_expr)                AS "avg_patient_mean_log10_IGF2_expr"
FROM lgg_clinical lc
JOIN per_patient_mean pp
  ON pp.patient_id = lc.patient_id
GROUP BY lc.histology_code
ORDER BY "avg_patient_mean_log10_IGF2_expr" DESC NULLS LAST;