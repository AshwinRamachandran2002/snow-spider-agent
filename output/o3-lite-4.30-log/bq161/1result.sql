WITH clinical_paad AS (
  SELECT DISTINCT bcr_patient_barcode AS patient_barcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE acronym = 'PAAD'
),
mutations_pass AS (
  SELECT DISTINCT ParticipantBarcode AS patient_barcode, Hugo_Symbol
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND FILTER = 'PASS'
    AND Hugo_Symbol IN ('KRAS','TP53')
),
kras AS (
  SELECT DISTINCT patient_barcode FROM mutations_pass WHERE Hugo_Symbol = 'KRAS'
),
tp53 AS (
  SELECT DISTINCT patient_barcode FROM mutations_pass WHERE Hugo_Symbol = 'TP53'
),
both AS (
  SELECT k.patient_barcode
  FROM kras k
  JOIN tp53 t
  ON k.patient_barcode = t.patient_barcode
),
neither AS (
  SELECT c.patient_barcode
  FROM clinical_paad c
  LEFT JOIN mutations_pass m
    ON c.patient_barcode = m.patient_barcode
  WHERE m.patient_barcode IS NULL
),
counts AS (
  SELECT 'patients_with_both' AS metric, COUNT(*) AS patient_count FROM both
  UNION ALL
  SELECT 'patients_with_neither', COUNT(*) FROM neither
),
final AS (
  SELECT * FROM counts
  UNION ALL
  SELECT 'net_difference',
         (SELECT patient_count FROM counts WHERE metric = 'patients_with_both')
       - (SELECT patient_count FROM counts WHERE metric = 'patients_with_neither')
)
SELECT metric, patient_count
FROM final
ORDER BY
  CASE metric
    WHEN 'patients_with_both'     THEN 1
    WHEN 'patients_with_neither'  THEN 2
    WHEN 'net_difference'         THEN 3
  END;