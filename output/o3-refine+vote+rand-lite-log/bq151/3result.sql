/*-----------------------------------------------------------
   Chi‑squared test for association between KRAS and TP53
   mutations in high‑quality PAAD (pancreatic adenocarcinoma)
   patients.
 -----------------------------------------------------------*/
WITH
-- 1)  PAAD patients that have clinical follow‑up information
paad_clin AS (
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE Study = 'PAAD'
),

-- 2)  Keep only patients that are on the TCGA white‑list
paad_whitelist AS (
  SELECT p.ParticipantBarcode
  FROM paad_clin p
  JOIN `isb-cgc-bq.pancancer_atlas.Whitelist_ParticipantBarcodes` w
    ON p.ParticipantBarcode = w.ParticipantBarcode
),

-- 3)  High‑quality mutation calls for KRAS or TP53 in PAAD
mut AS (
  SELECT DISTINCT ParticipantBarcode, Hugo_Symbol
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND Hugo_Symbol IN ('KRAS','TP53')
),

-- 4)  Flag each patient for the presence of KRAS and/or TP53 mutation
flags AS (
  SELECT
    pw.ParticipantBarcode,
    COUNTIF(Hugo_Symbol = 'KRAS') > 0 AS KRAS_mut,
    COUNTIF(Hugo_Symbol = 'TP53') > 0 AS TP53_mut
  FROM paad_whitelist pw
  LEFT JOIN mut m
    ON pw.ParticipantBarcode = m.ParticipantBarcode
  GROUP BY pw.ParticipantBarcode
),

-- 5)  Build 2×2 contingency table
cont AS (
  SELECT
    SUM(CASE WHEN KRAS_mut AND TP53_mut            THEN 1 ELSE 0 END) AS a_both,
    SUM(CASE WHEN KRAS_mut AND NOT TP53_mut        THEN 1 ELSE 0 END) AS b_kras_only,
    SUM(CASE WHEN NOT KRAS_mut AND TP53_mut        THEN 1 ELSE 0 END) AS c_tp53_only,
    SUM(CASE WHEN NOT KRAS_mut AND NOT TP53_mut    THEN 1 ELSE 0 END) AS d_neither
  FROM flags
),

-- 6)  Add marginal totals and expected counts
exp AS (
  SELECT
    a_both, b_kras_only, c_tp53_only, d_neither,
    (a_both + b_kras_only)                         AS row_kras_pos,
    (c_tp53_only + d_neither)                      AS row_kras_neg,
    (a_both + c_tp53_only)                         AS col_tp53_pos,
    (b_kras_only + d_neither)                      AS col_tp53_neg,
    (a_both + b_kras_only + c_tp53_only + d_neither) AS n_tot
  FROM cont
)

-- 7)  Final report with chi‑squared statistic
SELECT
  a_both      AS observed_both_mutated,
  b_kras_only AS observed_KRAS_only,
  c_tp53_only AS observed_TP53_only,
  d_neither   AS observed_neither,

  -- expected frequencies
  (row_kras_pos * col_tp53_pos) / n_tot AS expected_both_mutated,
  (row_kras_pos * col_tp53_neg) / n_tot AS expected_KRAS_only,
  (row_kras_neg * col_tp53_pos) / n_tot AS expected_TP53_only,
  (row_kras_neg * col_tp53_neg) / n_tot AS expected_neither,

  -- chi‑squared statistic (1 degree of freedom for 2×2 table)
  (
    POWER(a_both      - (row_kras_pos * col_tp53_pos) / n_tot, 2) /
         ((row_kras_pos * col_tp53_pos) / n_tot)
    +
    POWER(b_kras_only - (row_kras_pos * col_tp53_neg) / n_tot, 2) /
         ((row_kras_pos * col_tp53_neg) / n_tot)
    +
    POWER(c_tp53_only - (row_kras_neg * col_tp53_pos) / n_tot, 2) /
         ((row_kras_neg * col_tp53_pos) / n_tot)
    +
    POWER(d_neither   - (row_kras_neg * col_tp53_neg) / n_tot, 2) /
         ((row_kras_neg * col_tp53_neg) / n_tot)
  ) AS chi_squared_statistic
FROM exp;