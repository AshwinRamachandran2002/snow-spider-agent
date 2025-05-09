/*  Average per-histology IGF2 expression (log10-scaled) in LGG  */

WITH patient_level AS (
  /* ---- 1.  Compute per-patient average log10( normalized_count + 1 ) ---- */
  SELECT
      g."ParticipantBarcode",
      AVG( LOG(10, g."normalized_count" + 1) )    AS "patient_avg_log10_expr"
  FROM  PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED  g
  WHERE
        g."Symbol"               = 'IGF2'
    AND g."Study"                = 'LGG'                -- brain lower-grade glioma
    AND g."SampleTypeLetterCode" = 'TP'                 -- primary solid tumour samples
    AND g."normalized_count"     IS NOT NULL
  GROUP BY
      g."ParticipantBarcode"
)

SELECT
    c."icd_o_3_histology",
    AVG( p."patient_avg_log10_expr" )  AS "mean_patient_avg_log10_expr"
FROM  patient_level  p
JOIN  PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED  c
      ON p."ParticipantBarcode" = c."bcr_patient_barcode"
WHERE
      c."acronym" = 'LGG'
  AND c."icd_o_3_histology" NOT ILIKE '[%'           -- exclude bracketed placeholders
GROUP BY
    c."icd_o_3_histology"
ORDER BY
    c."icd_o_3_histology";