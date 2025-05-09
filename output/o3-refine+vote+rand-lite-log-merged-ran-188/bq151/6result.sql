/*  Chi‑square test for association between KRAS and TP53 mutations in PAAD  */

WITH clinical_paads AS (
  -- 1.  All PAAD patients with follow‑up information (guarantees valid clinical IDs)
  SELECT DISTINCT
         bcr_patient_barcode AS ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE  acronym = 'PAAD'
),
mut_flags AS (
  -- 2.  Per‑patient mutation flags from high‑quality MC3 file
  SELECT
    ParticipantBarcode,
    MAX(CASE WHEN Hugo_Symbol = 'KRAS'  THEN 1 ELSE 0 END) AS has_KRAS,
    MAX(CASE WHEN Hugo_Symbol = 'TP53'  THEN 1 ELSE 0 END) AS has_TP53
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
  GROUP BY ParticipantBarcode
),
patient_matrix AS (
  -- 3.  Merge clinical list with mutation flags (patients with no mutation = 0)
  SELECT
    c.ParticipantBarcode,
    IFNULL(m.has_KRAS, 0) AS has_KRAS,
    IFNULL(m.has_TP53, 0) AS has_TP53
  FROM clinical_paads c
  LEFT JOIN mut_flags m
  USING (ParticipantBarcode)
),
obs AS (
  -- 4.  Observed 2×2 contingency counts
  SELECT
    COUNTIF( has_KRAS = 1 AND has_TP53 = 1 ) AS both_mut,
    COUNTIF( has_KRAS = 1 AND has_TP53 = 0 ) AS kras_only,
    COUNTIF( has_KRAS = 0 AND has_TP53 = 1 ) AS tp53_only,
    COUNTIF( has_KRAS = 0 AND has_TP53 = 0 ) AS neither,
    COUNT(*)                                    AS n_patients,
    SUM(has_KRAS)                               AS n_kras,
    SUM(has_TP53)                               AS n_tp53
  FROM patient_matrix
),
exp AS (
  -- 5.  Expected counts under independence
  SELECT
    *,
    (n_kras  * n_tp53)            / n_patients AS exp_both,
    (n_kras  * (n_patients-n_tp53))/ n_patients AS exp_kras_only,
    ((n_patients-n_kras) * n_tp53)/ n_patients AS exp_tp53_only,
    ((n_patients-n_kras) * (n_patients-n_tp53)) / n_patients AS exp_neither
  FROM obs
)
-- 6.  χ² statistic
SELECT
  n_patients                                                      AS total_patients,
  both_mut,   exp_both,
  kras_only,  exp_kras_only,
  tp53_only,  exp_tp53_only,
  neither,    exp_neither,
  -- χ² = Σ (O−E)² / E   for 4 cells
  ((both_mut    - exp_both   )*(both_mut    - exp_both   )/exp_both)   +
  ((kras_only   - exp_kras_only)*(kras_only - exp_kras_only)/exp_kras_only) +
  ((tp53_only   - exp_tp53_only)*(tp53_only - exp_tp53_only)/exp_tp53_only) +
  ((neither     - exp_neither )*(neither    - exp_neither )/exp_neither)     AS chi_squared_statistic
FROM exp;