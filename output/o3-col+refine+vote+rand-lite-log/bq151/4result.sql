/*  Chi-squared test of independence between KRAS and TP53
    mutations in pancreatic adenocarcinoma (PAAD) patients      */

WITH
/* ----------------------------------------------------------------------
   1.  All PAAD patients that have clinical follow-up (denominator set)
------------------------------------------------------------------------ */
patients AS (
  SELECT DISTINCT ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE  Study = 'PAAD'
),

/* ----------------------------------------------------------------------
   2.  High-quality (PASS) KRAS and TP53 mutation flags
------------------------------------------------------------------------ */
kras AS (
  SELECT DISTINCT ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE  Study = 'PAAD'
    AND  Hugo_Symbol = 'KRAS'
    AND  FILTER = 'PASS'                 -- keep only high-quality calls
),
tp53 AS (
  SELECT DISTINCT ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE  Study = 'PAAD'
    AND  Hugo_Symbol = 'TP53'
    AND  FILTER = 'PASS'
),

/* ----------------------------------------------------------------------
   3.  One row per patient with 0/1 mutation flags
------------------------------------------------------------------------ */
flags AS (
  SELECT  p.ParticipantBarcode,
          IF(k.ParticipantBarcode IS NOT NULL, 1, 0) AS KRAS_mut,
          IF(t.ParticipantBarcode IS NOT NULL, 1, 0) AS TP53_mut
  FROM    patients p
  LEFT JOIN kras k USING (ParticipantBarcode)
  LEFT JOIN tp53 t USING (ParticipantBarcode)
),

/* ----------------------------------------------------------------------
   4.  Four observed frequencies for 2×2 contingency table
------------------------------------------------------------------------ */
obs AS (
  SELECT
    SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS a_both,
    SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS b_kras_only,
    SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS c_tp53_only,
    SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS d_neither
  FROM flags
),

/* ----------------------------------------------------------------------
   5.  Expected counts under independence and χ² statistic
------------------------------------------------------------------------ */
chi2 AS (
  SELECT
    a_both, b_kras_only, c_tp53_only, d_neither,
    -- marginal totals
    (a_both + b_kras_only)                       AS row_KRAS_pos,
    (c_tp53_only + d_neither)                    AS row_KRAS_neg,
    (a_both + c_tp53_only)                       AS col_TP53_pos,
    (b_kras_only + d_neither)                    AS col_TP53_neg,
    (a_both + b_kras_only + c_tp53_only + d_neither) AS n_total
  FROM obs
),
calc AS (
  SELECT
    a_both, b_kras_only, c_tp53_only, d_neither, n_total,
    -- expected counts (as FLOAT64)
    (row_KRAS_pos * col_TP53_pos) / n_total      AS exp_a,
    (row_KRAS_pos * col_TP53_neg) / n_total      AS exp_b,
    (row_KRAS_neg * col_TP53_pos) / n_total      AS exp_c,
    (row_KRAS_neg * col_TP53_neg) / n_total      AS exp_d
  FROM chi2
)

/* ----------------------------------------------------------------------
   6.  Final output with χ² statistic
------------------------------------------------------------------------ */
SELECT
  a_both              AS KRAS_TP53_both,
  b_kras_only         AS KRAS_only,
  c_tp53_only         AS TP53_only,
  d_neither           AS Neither,
  n_total             AS Total_Patients,
  -- χ² = Σ (O−E)² / E
  ROUND(
        ((a_both   - exp_a) * (a_both   - exp_a)) / exp_a +
        ((b_kras_only - exp_b) * (b_kras_only - exp_b)) / exp_b +
        ((c_tp53_only - exp_c) * (c_tp53_only - exp_c)) / exp_c +
        ((d_neither   - exp_d) * (d_neither   - exp_d)) / exp_d
  , 4)                AS Chi_squared_statistic
FROM calc;