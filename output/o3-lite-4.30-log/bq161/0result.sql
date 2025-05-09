WITH paad_patients AS (
  SELECT DISTINCT `bcr_patient_barcode` AS patient_barcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE `acronym` = 'PAAD'
),
mutation_flags AS (
  SELECT
    `ParticipantBarcode` AS patient_barcode,
    MAX(CASE WHEN `Hugo_Symbol` = 'KRAS' THEN 1 ELSE 0 END) AS has_kras,
    MAX(CASE WHEN `Hugo_Symbol` = 'TP53' THEN 1 ELSE 0 END) AS has_tp53
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE `Study` = 'PAAD'
    AND `FILTER` = 'PASS'
    AND `Hugo_Symbol` IN ('KRAS', 'TP53')
  GROUP BY patient_barcode
),
combined AS (
  SELECT
    p.patient_barcode,
    IFNULL(m.has_kras, 0) AS has_kras,
    IFNULL(m.has_tp53, 0) AS has_tp53
  FROM paad_patients p
  LEFT JOIN mutation_flags m
    ON p.patient_barcode = m.patient_barcode
),
summary AS (
  SELECT
    SUM(CASE WHEN has_kras = 1 AND has_tp53 = 1 THEN 1 ELSE 0 END) AS both_mut,
    SUM(CASE WHEN has_kras = 0 AND has_tp53 = 0 THEN 1 ELSE 0 END) AS neither_mut
  FROM combined
)
SELECT
  'net_difference' AS metric,
  (both_mut - neither_mut) AS patient_count
FROM summary;