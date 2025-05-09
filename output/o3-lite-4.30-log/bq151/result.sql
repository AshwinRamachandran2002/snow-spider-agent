WITH
/* 1. clinical barcodes */
clinical AS (
  SELECT DISTINCT
         bcr_patient_barcode AS ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
),
/* 2. PAAD barcodes in mutation table */
paad_mut AS (
  SELECT DISTINCT
         ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE  Study = 'PAAD'
),
/* 3. Patients having BOTH mutation and clinical data */
patients AS (
  SELECT pm.ParticipantBarcode
  FROM   paad_mut pm
  JOIN   clinical USING (ParticipantBarcode)
),
/* 4. KRAS‑mutated patients (high‑quality calls) */
kras AS (
  SELECT DISTINCT
         ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE  Study = 'PAAD'
    AND  FILTER = 'PASS'
    AND  Hugo_Symbol = 'KRAS'
),
/* 5. TP53‑mutated patients (high‑quality calls) */
tp53 AS (
  SELECT DISTINCT
         ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE  Study = 'PAAD'
    AND  FILTER = 'PASS'
    AND  Hugo_Symbol = 'TP53'
),
/* 6. Label each patient */
labelled AS (
  SELECT
    p.ParticipantBarcode,
    IF(k.ParticipantBarcode IS NOT NULL, 1, 0) AS KRAS_mut,
    IF(t.ParticipantBarcode IS NOT NULL, 1, 0) AS TP53_mut
  FROM patients p
  LEFT JOIN kras k USING (ParticipantBarcode)
  LEFT JOIN tp53 t USING (ParticipantBarcode)
),
/* 7. Observed counts */
obs AS (
  SELECT
    SUM(CASE WHEN KRAS_mut=1 AND TP53_mut=1 THEN 1 ELSE 0 END) AS both_mut,
    SUM(CASE WHEN KRAS_mut=1 AND TP53_mut=0 THEN 1 ELSE 0 END) AS kras_only,
    SUM(CASE WHEN KRAS_mut=0 AND TP53_mut=1 THEN 1 ELSE 0 END) AS tp53_only,
    SUM(CASE WHEN KRAS_mut=0 AND TP53_mut=0 THEN 1 ELSE 0 END) AS neither
  FROM labelled
),
/* 8. Chi‑square calculation */
chi_calc AS (
  SELECT
    both_mut,
    kras_only,
    tp53_only,
    neither,
    (both_mut + kras_only)                        AS row_kras_yes,
    (tp53_only + neither)                         AS row_kras_no,
    (both_mut + tp53_only)                        AS col_tp53_yes,
    (kras_only + neither)                         AS col_tp53_no,
    (both_mut + kras_only + tp53_only + neither)  AS n_total
  FROM obs
),
expected AS (
  SELECT
    *,
    (row_kras_yes * col_tp53_yes) / n_total AS exp_a,
    (row_kras_yes * col_tp53_no ) / n_total AS exp_b,
    (row_kras_no  * col_tp53_yes) / n_total AS exp_c,
    (row_kras_no  * col_tp53_no ) / n_total AS exp_d
  FROM chi_calc
),
stat AS (
  SELECT
    both_mut,
    kras_only,
    tp53_only,
    neither,
    ROUND(
      (POW(both_mut  - exp_a, 2) / exp_a) +
      (POW(kras_only - exp_b, 2) / exp_b) +
      (POW(tp53_only - exp_c, 2) / exp_c) +
      (POW(neither   - exp_d, 2) / exp_d)
    , 4) AS chi_squared
  FROM expected
)
/* 9. Final tidy output */
SELECT category, value
FROM (
  SELECT 'both_mut'   AS category, CAST(both_mut   AS STRING)          AS value FROM stat
  UNION ALL
  SELECT 'kras_only'  , CAST(kras_only AS STRING)                       FROM stat
  UNION ALL
  SELECT 'tp53_only'  , CAST(tp53_only AS STRING)                       FROM stat
  UNION ALL
  SELECT 'neither'    , CAST(neither   AS STRING)                       FROM stat
  UNION ALL
  SELECT 'chi_squared', FORMAT('%.4f', chi_squared)                     FROM stat
)
ORDER BY
  CASE category
    WHEN 'both_mut'    THEN 1
    WHEN 'kras_only'   THEN 2
    WHEN 'tp53_only'   THEN 3
    WHEN 'neither'     THEN 4
    ELSE 5
  END;