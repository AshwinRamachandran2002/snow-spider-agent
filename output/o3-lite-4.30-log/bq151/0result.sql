WITH paad_cohort AS (
  -- all PAAD patients in clinical follow‑up table
  SELECT
    `bcr_patient_barcode` AS patient_id
  FROM
    `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE
    `acronym` = 'PAAD'
),
paad_mut AS (
  -- mutation flags for high‑quality KRAS / TP53 calls
  SELECT
    `ParticipantBarcode` AS patient_id,
    MAX(CASE WHEN `Hugo_Symbol` = 'KRAS' THEN 1 ELSE 0 END) AS has_KRAS,
    MAX(CASE WHEN `Hugo_Symbol` = 'TP53' THEN 1 ELSE 0 END) AS has_TP53
  FROM
    `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE
        `Study`  = 'PAAD'
    AND `FILTER` = 'PASS'
    AND `Hugo_Symbol` IN ('KRAS','TP53')
  GROUP BY
    patient_id
),
joined AS (
  -- ensure every PAAD patient has explicit 0/1 flags
  SELECT
    c.patient_id,
    IFNULL(m.has_KRAS, 0) AS has_KRAS,
    IFNULL(m.has_TP53, 0) AS has_TP53
  FROM
    paad_cohort c
  LEFT JOIN
    paad_mut   m
  ON
    c.patient_id = m.patient_id
),
contingency AS (
  SELECT
    SUM(CASE WHEN has_KRAS = 1 AND has_TP53 = 1 THEN 1 ELSE 0 END) AS both_mut,
    SUM(CASE WHEN has_KRAS = 1 AND has_TP53 = 0 THEN 1 ELSE 0 END) AS kras_only,
    SUM(CASE WHEN has_KRAS = 0 AND has_TP53 = 1 THEN 1 ELSE 0 END) AS tp53_only,
    SUM(CASE WHEN has_KRAS = 0 AND has_TP53 = 0 THEN 1 ELSE 0 END) AS neither
  FROM joined
),
expected AS (
  SELECT
    * ,
    (both_mut + kras_only + tp53_only + neither) AS total,
    (both_mut + kras_only)                      AS row_kras_yes,
    (tp53_only + neither)                       AS row_kras_no,
    (both_mut + tp53_only)                      AS col_tp53_yes,
    (kras_only + neither)                       AS col_tp53_no
  FROM contingency
),
chi_components AS (
  SELECT
    both_mut, kras_only, tp53_only, neither,
    row_kras_yes * col_tp53_yes / total AS E_both,
    row_kras_yes * col_tp53_no  / total AS E_kras_only,
    row_kras_no  * col_tp53_yes / total AS E_tp53_only,
    row_kras_no  * col_tp53_no  / total AS E_neither
  FROM expected
),
chi_square AS (
  SELECT
      SAFE_DIVIDE(POW(both_mut  - E_both     , 2), E_both     ) +
      SAFE_DIVIDE(POW(kras_only - E_kras_only, 2), E_kras_only) +
      SAFE_DIVIDE(POW(tp53_only - E_tp53_only, 2), E_tp53_only) +
      SAFE_DIVIDE(POW(neither   - E_neither  , 2), E_neither  ) AS chi_statistic
  FROM chi_components
)
SELECT
  'chi_squared_statistic' AS category,
  ROUND(chi_statistic, 4)  AS value
FROM chi_square;