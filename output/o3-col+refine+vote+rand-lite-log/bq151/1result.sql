/*--------------------------------------------------------------------
  Chi-square test of independence between KRAS and TP53 mutations
  in pancreatic adenocarcinoma (PAAD) patients who have clinical
  follow-up information in the TCGA Clinical Data Resource (CDR).
--------------------------------------------------------------------*/
WITH cdr AS (   -- PAAD patients with follow-up data
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE Study = 'PAAD'
),

kras_mut AS (   -- high-quality KRAS mutations
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND FILTER = 'PASS'
    AND Hugo_Symbol = 'KRAS'
),

tp53_mut AS (   -- high-quality TP53 mutations
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND FILTER = 'PASS'
    AND Hugo_Symbol = 'TP53'
),

/* Mutation status (1 = mutated, 0 = wild-type) for every
   PAAD patient in the clinical cohort */
mut_status AS (
  SELECT
    c.ParticipantBarcode,
    IF(k.ParticipantBarcode IS NOT NULL, 1, 0) AS KRAS_mut,
    IF(t.ParticipantBarcode IS NOT NULL, 1, 0) AS TP53_mut
  FROM cdr c
  LEFT JOIN kras_mut k USING (ParticipantBarcode)
  LEFT JOIN tp53_mut t USING (ParticipantBarcode)
),

/* 2×2 contingency table */
contingency AS (
  SELECT
    KRAS_mut,
    TP53_mut,
    COUNT(*) AS n
  FROM mut_status
  GROUP BY KRAS_mut, TP53_mut
),

/* Row/column totals needed for expected counts */
totals AS (
  SELECT
    SUM(n)                                                     AS grand,
    SUM(CASE WHEN KRAS_mut = 1 THEN n END)                    AS row_kras1,
    SUM(CASE WHEN KRAS_mut = 0 THEN n END)                    AS row_kras0,
    SUM(CASE WHEN TP53_mut = 1 THEN n END)                    AS col_tp531,
    SUM(CASE WHEN TP53_mut = 0 THEN n END)                    AS col_tp530
  FROM contingency
),

/* Expected counts and χ² contribution for each cell */
cell_stats AS (
  SELECT
    c.KRAS_mut,
    c.TP53_mut,
    c.n,
    CASE                                                      -- expected count
      WHEN c.KRAS_mut = 1 AND c.TP53_mut = 1 THEN t.row_kras1 * t.col_tp531 / t.grand
      WHEN c.KRAS_mut = 1 AND c.TP53_mut = 0 THEN t.row_kras1 * t.col_tp530 / t.grand
      WHEN c.KRAS_mut = 0 AND c.TP53_mut = 1 THEN t.row_kras0 * t.col_tp531 / t.grand
      ELSE                                                     t.row_kras0 * t.col_tp530 / t.grand
    END AS expected,
    -- χ² component = (observed-expected)² / expected
    POWER(
      c.n -
      CASE
        WHEN c.KRAS_mut = 1 AND c.TP53_mut = 1 THEN t.row_kras1 * t.col_tp531 / t.grand
        WHEN c.KRAS_mut = 1 AND c.TP53_mut = 0 THEN t.row_kras1 * t.col_tp530 / t.grand
        WHEN c.KRAS_mut = 0 AND c.TP53_mut = 1 THEN t.row_kras0 * t.col_tp531 / t.grand
        ELSE                                                     t.row_kras0 * t.col_tp530 / t.grand
      END
    ,2) /
    CASE
      WHEN c.KRAS_mut = 1 AND c.TP53_mut = 1 THEN t.row_kras1 * t.col_tp531 / t.grand
      WHEN c.KRAS_mut = 1 AND c.TP53_mut = 0 THEN t.row_kras1 * t.col_tp530 / t.grand
      WHEN c.KRAS_mut = 0 AND c.TP53_mut = 1 THEN t.row_kras0 * t.col_tp531 / t.grand
      ELSE                                                     t.row_kras0 * t.col_tp530 / t.grand
    END AS chi_component
  FROM contingency c
  CROSS JOIN totals t
)

/* Final chi-square statistic (df = 1 for a 2×2 table) */
SELECT
  SUM(chi_component) AS chi_squared_statistic,
  1                  AS degrees_of_freedom
FROM cell_stats;