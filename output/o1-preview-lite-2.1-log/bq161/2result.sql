SELECT
  (COUNTIF(KRAS_mut = 1 AND TP53_mut = 1) - COUNTIF(KRAS_mut = 0 AND TP53_mut = 0)) AS difference
FROM (
    SELECT 
        c.`bcr_patient_barcode` AS ParticipantBarcode,
        MAX(CASE WHEN m.`Hugo_Symbol` = 'KRAS' THEN 1 ELSE 0 END) AS KRAS_mut,
        MAX(CASE WHEN m.`Hugo_Symbol` = 'TP53' THEN 1 ELSE 0 END) AS TP53_mut
    FROM 
        `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup` c
    LEFT JOIN
        (
          SELECT DISTINCT `ParticipantBarcode`, `Hugo_Symbol`
          FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
          WHERE `FILTER` = 'PASS' AND `Hugo_Symbol` IN ('KRAS', 'TP53')
        ) m
    ON
        c.`bcr_patient_barcode` = m.`ParticipantBarcode`
    WHERE
        c.`acronym` = 'PAAD'
    GROUP BY
        c.`bcr_patient_barcode`
)