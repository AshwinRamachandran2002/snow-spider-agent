WITH all_paad AS (
  SELECT DISTINCT `bcr_patient_barcode` AS patient
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE `acronym` = 'PAAD'
),
mutations AS (
  SELECT DISTINCT `ParticipantBarcode` AS patient,
                  `Hugo_Symbol`
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE `Study`  = 'PAAD'
    AND `FILTER` = 'PASS'
    AND `Hugo_Symbol` IN ('KRAS','TP53')
),
both_patients AS (
  SELECT patient
  FROM mutations
  GROUP BY patient
  HAVING COUNT(DISTINCT `Hugo_Symbol`) = 2
),
either_patient AS (
  SELECT DISTINCT patient
  FROM mutations
),
neither_patients AS (
  SELECT patient
  FROM all_paad
  WHERE patient NOT IN (SELECT patient FROM either_patient)
)
SELECT 'net_difference' AS metric,
       FORMAT('%.4f', CAST(
         (SELECT COUNT(*) FROM both_patients) -
         (SELECT COUNT(*) FROM neither_patients) AS FLOAT64)
       ) AS patient_count;