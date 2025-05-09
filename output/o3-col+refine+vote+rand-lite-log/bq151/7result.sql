/* ---------------------------------------------------------------------------
   Chi-squared test of independence between KRAS and TP53 mutations in
   whitelisted PAAD patients (TCGA).
   --------------------------------------------------------------------------- */
WITH
/* 1.  Build the PAAD patient universe that has clinical follow-up data
       (TCGA_CDR) AND passes the Pan-Cancer quality whitelist.               */
universe AS (
  SELECT DISTINCT c.ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`                    AS c
  JOIN `isb-cgc-bq.pancancer_atlas.Whitelist_ParticipantBarcodes` AS w
    ON c.ParticipantBarcode = w.ParticipantBarcode
  WHERE c.Study = 'PAAD'
),

/* 2.  High-quality mutation calls for KRAS and TP53 (MC3, one per tumor
       sample, AWG-filtered).                                                */
kras AS (
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD' AND Hugo_Symbol = 'KRAS'
),
tp53 AS (
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD' AND Hugo_Symbol = 'TP53'
),

/* 3.  Flag each patient for KRAS / TP53 mutation presence.                  */
flagged AS (
  SELECT
    u.ParticipantBarcode,
    IF(k.ParticipantBarcode IS NOT NULL, 1, 0) AS KRAS_mut,
    IF(t.ParticipantBarcode IS NOT NULL, 1, 0) AS TP53_mut
  FROM universe AS u
  LEFT JOIN kras AS k  USING (ParticipantBarcode)
  LEFT JOIN tp53 AS t  USING (ParticipantBarcode)
),

/* 4.  2×2 contingency-table counts.                                         */
agg AS (
  SELECT
    SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS both_mut,
    SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS kras_only,
    SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS tp53_only,
    SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS neither_mut
  FROM flagged
),

/* 5.  Row / column totals, expected counts & χ² components.                 */
chi AS (
  SELECT
    both_mut,
    kras_only,
    tp53_only,
    neither_mut,
    /* totals */
    (both_mut + kras_only + tp53_only + neither_mut)            AS grand_total,
    (both_mut + kras_only)                                      AS row_kras1,
    (tp53_only + neither_mut)                                   AS row_kras0,
    (both_mut + tp53_only)                                      AS col_tp531,
    (kras_only + neither_mut)                                   AS col_tp530
  FROM agg
)

/* 6.  Final report with observed & expected counts plus χ² statistic.       */
SELECT
  /* observed counts */
  both_mut       AS obs_both_mut,
  kras_only      AS obs_kras_only,
  tp53_only      AS obs_tp53_only,
  neither_mut    AS obs_neither_mut,

  /* expected counts */
  ROUND((row_kras1 * col_tp531) / grand_total, 2) AS exp_both_mut,
  ROUND((row_kras1 * col_tp530) / grand_total, 2) AS exp_kras_only,
  ROUND((row_kras0 * col_tp531) / grand_total, 2) AS exp_tp53_only,
  ROUND((row_kras0 * col_tp530) / grand_total, 2) AS exp_neither_mut,

  /* chi-square statistic (df = 1) */
  ROUND(
      POW(both_mut    - (row_kras1 * col_tp531) / grand_total, 2) / ((row_kras1 * col_tp531) / grand_total) +
      POW(kras_only   - (row_kras1 * col_tp530) / grand_total, 2) / ((row_kras1 * col_tp530) / grand_total) +
      POW(tp53_only   - (row_kras0 * col_tp531) / grand_total, 2) / ((row_kras0 * col_tp531) / grand_total) +
      POW(neither_mut - (row_kras0 * col_tp530) / grand_total, 2) / ((row_kras0 * col_tp530) / grand_total)
    , 4) AS chi_squared_statistic
FROM chi;