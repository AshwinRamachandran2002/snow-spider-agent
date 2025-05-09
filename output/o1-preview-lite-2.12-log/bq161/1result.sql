SELECT
  (
    SELECT COUNT(DISTINCT k.ParticipantBarcode)
    FROM (
      SELECT ParticipantBarcode
      FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
      WHERE LOWER(Study) = 'paad' AND Hugo_Symbol = 'KRAS' AND FILTER = 'PASS'
    ) AS k
    INNER JOIN (
      SELECT ParticipantBarcode
      FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
      WHERE LOWER(Study) = 'paad' AND Hugo_Symbol = 'TP53' AND FILTER = 'PASS'
    ) AS t
    ON k.ParticipantBarcode = t.ParticipantBarcode
  )
  -
  (
    SELECT COUNT(DISTINCT bcr_patient_barcode)
    FROM `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
    WHERE LOWER(acronym) = 'paad'
    AND bcr_patient_barcode NOT IN (
      SELECT DISTINCT ParticipantBarcode
      FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
      WHERE LOWER(Study) = 'paad' AND Hugo_Symbol IN ('KRAS', 'TP53') AND FILTER = 'PASS'
    )
  ) AS difference