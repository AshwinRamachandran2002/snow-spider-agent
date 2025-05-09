/* -----------------------------------------------------------
   Chi-squared test for association between KRAS and TP53
   mutations in high-quality PAAD (pancreatic adenocarcinoma)
   TCGA patients.

   –  Start from whitelisted participants that also have
      clinical follow-up information (TCGA_CDR).
   –  Build patient-level mutation flags from the AWG-
      curated “one-per-tumour-sample” MC3 file.
   –  Assemble the 2×2 contingency table.
   –  Compute the Pearson chi-squared statistic.
   ----------------------------------------------------------- */

WITH base AS (          -- high-quality PAAD patients with follow-up
  SELECT DISTINCT c.ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`                 AS c
  JOIN `isb-cgc-bq.pancancer_atlas.Whitelist_ParticipantBarcodes` AS w
        ON c.ParticipantBarcode = w.ParticipantBarcode
  WHERE c.Study = 'PAAD'
),

flags AS (              -- mutation flags per patient
  SELECT
    b.ParticipantBarcode,
    MAX(CASE WHEN m.Hugo_Symbol = 'KRAS'  THEN 1 ELSE 0 END) AS KRAS_mut,
    MAX(CASE WHEN m.Hugo_Symbol = 'TP53'  THEN 1 ELSE 0 END) AS TP53_mut
  FROM base AS b
  LEFT JOIN `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample` AS m
         ON b.ParticipantBarcode = m.ParticipantBarcode
        AND m.Study            = 'PAAD'
        AND m.Hugo_Symbol IN ('KRAS','TP53')
  GROUP BY b.ParticipantBarcode
),

contingency AS (        -- 2×2 table
  SELECT
    SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS both_mut,
    SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS kras_only,
    SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS tp53_only,
    SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS neither_mut
  FROM flags
),

expected AS (           -- row/column totals & expected counts
  SELECT
    both_mut, kras_only, tp53_only, neither_mut,
    (both_mut + kras_only + tp53_only + neither_mut)                 AS N,
    (both_mut + kras_only)                                           AS KRAS_tot,
    (both_mut + tp53_only)                                           AS TP53_tot
  FROM contingency
),

chi2 AS (
  SELECT
    both_mut,
    kras_only,
    tp53_only,
    neither_mut,

    -- expected values
    (KRAS_tot * TP53_tot)        / N               AS exp_both,
    (KRAS_tot * (N-TP53_tot))    / N               AS exp_kras_only,
    ((N-KRAS_tot) * TP53_tot)    / N               AS exp_tp53_only,
    ((N-KRAS_tot) * (N-TP53_tot))/ N               AS exp_neither,

    -- Pearson chi-squared statistic
    (POW(both_mut    - (KRAS_tot * TP53_tot)        / N, 2) /
         ((KRAS_tot * TP53_tot)                      / N) ) +
    (POW(kras_only   - (KRAS_tot * (N-TP53_tot))    / N, 2) /
         ((KRAS_tot * (N-TP53_tot))                  / N) ) +
    (POW(tp53_only   - ((N-KRAS_tot) * TP53_tot)    / N, 2) /
         (((N-KRAS_tot) * TP53_tot)                  / N) ) +
    (POW(neither_mut - ((N-KRAS_tot) * (N-TP53_tot))/ N, 2) /
         (((N-KRAS_tot) * (N-TP53_tot))              / N) )   AS chi_squared_statistic
  FROM expected
)

SELECT
  both_mut     AS KRAS_and_TP53,
  kras_only    AS KRAS_only,
  tp53_only    AS TP53_only,
  neither_mut  AS Neither,
  chi_squared_statistic
FROM chi2;