/* ----------------------------------------------------------------------
   Chi‑squared test for the association between KRAS and TP53 mutations
   in TCGA Pancreatic Adenocarcinoma (PAAD) patients
   -------------------------------------------------------------------- */
WITH mutation_flags AS (
  /* 1.  Retrieve non‑silent mutation flags for KRAS and TP53 */
  SELECT
    ParticipantBarcode,
    MAX(CASE WHEN Hugo_Symbol = 'KRAS'  AND Variant_Classification <> 'Silent' THEN 1 ELSE 0 END) AS KRAS_mut,
    MAX(CASE WHEN Hugo_Symbol = 'TP53'  AND Variant_Classification <> 'Silent' THEN 1 ELSE 0 END) AS TP53_mut
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
  GROUP BY ParticipantBarcode
),
patients AS (
  /* 2.  Keep only PAAD patients with clinical follow‑up data */
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE Study = 'PAAD'
),
flags AS (
  /* 3.  Merge clinical cohort with mutation flags (missing = wild‑type) */
  SELECT
    p.ParticipantBarcode,
    IFNULL(m.KRAS_mut, 0) AS KRAS_mut,
    IFNULL(m.TP53_mut, 0) AS TP53_mut
  FROM patients p
  LEFT JOIN mutation_flags m
    USING (ParticipantBarcode)
),
contingency AS (
  /* 4.  Build 2×2 contingency table */
  SELECT
    SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS both_mut,
    SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS kras_only,
    SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS tp53_only,
    SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS neither
  FROM flags
),
chi_intermediate AS (
  /* 5.  Row/column totals and grand total */
  SELECT
    both_mut,
    kras_only,
    tp53_only,
    neither,
    (both_mut + kras_only)              AS KRAS_total,
    (tp53_only + neither)              AS KRAS_WT_total,
    (both_mut + tp53_only)             AS TP53_total,
    (kras_only + neither)              AS TP53_WT_total,
    (both_mut + kras_only + tp53_only + neither) AS grand_total
  FROM contingency
),
expected AS (
  /* 6.  Expected counts under independence */
  SELECT
    *,
    (KRAS_total    * TP53_total)   / grand_total AS exp_both,
    (KRAS_total    * TP53_WT_total) / grand_total AS exp_kras_only,
    (KRAS_WT_total * TP53_total)   / grand_total AS exp_tp53_only,
    (KRAS_WT_total * TP53_WT_total) / grand_total AS exp_neither
  FROM chi_intermediate
)
SELECT
  both_mut,
  kras_only,
  tp53_only,
  neither,
  exp_both,
  exp_kras_only,
  exp_tp53_only,
  exp_neither,
  /* 7.  Chi‑squared statistic (1 degree of freedom) */
  (
    POW(both_mut   - exp_both,      2) / exp_both      +
    POW(kras_only  - exp_kras_only, 2) / exp_kras_only +
    POW(tp53_only  - exp_tp53_only, 2) / exp_tp53_only +
    POW(neither    - exp_neither,   2) / exp_neither
  ) AS chi_squared_statistic
FROM expected;