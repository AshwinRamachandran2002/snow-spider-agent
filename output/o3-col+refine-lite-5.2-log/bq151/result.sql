-- Chi‑squared test for association between KRAS and TP53 mutations in PAAD
WITH
/* 1.  Clinical PAAD cohort (follow‑up available, not redacted) */
cdr AS (
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE Study = 'PAAD'
    AND Redaction IS NULL
),

/* 2.  TCGA quality whitelist (high‑confidence patients) */
whitelist AS (
  SELECT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Whitelist_ParticipantBarcodes`
),

/* 3.  Mutation flags from high‑quality MC3 MAF (one row / patient) */
mut_flags AS (
  SELECT
    ParticipantBarcode,
    MAX(Hugo_Symbol = 'KRAS') AS KRAS_mut,   -- TRUE if ≥1 KRAS mutation
    MAX(Hugo_Symbol = 'TP53') AS TP53_mut    -- TRUE if ≥1 TP53 mutation
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
  GROUP BY ParticipantBarcode
),

/* 4.  Final patient set (present in CDR & whitelist) */
valid AS (
  SELECT f.ParticipantBarcode, KRAS_mut, TP53_mut
  FROM mut_flags  AS f
  JOIN cdr        USING (ParticipantBarcode)
  JOIN whitelist  USING (ParticipantBarcode)
),

/* 5.  2×2 contingency table counts */
cont AS (
  SELECT
    SUM(CASE WHEN  KRAS_mut AND  TP53_mut THEN 1 ELSE 0 END) AS a_both,        -- KRAS+ / TP53+
    SUM(CASE WHEN  KRAS_mut AND NOT TP53_mut THEN 1 ELSE 0 END) AS b_kras_only,-- KRAS+ / TP53–
    SUM(CASE WHEN NOT KRAS_mut AND  TP53_mut THEN 1 ELSE 0 END) AS c_tp53_only,-- KRAS– / TP53+
    SUM(CASE WHEN NOT KRAS_mut AND NOT TP53_mut THEN 1 ELSE 0 END) AS d_neither-- KRAS– / TP53–
  FROM valid
),

/* 6.  Chi‑squared statistic (1 degree of freedom) */
chi AS (
  SELECT
    a_both AS a,
    b_kras_only AS b,
    c_tp53_only AS c,
    d_neither AS d,
    (a_both + b_kras_only + c_tp53_only + d_neither) AS n
  FROM cont
)

SELECT
  a, b, c, d, n,
  -- expected counts under independence
  ((a+b)*(a+c))/n AS exp_a,
  ((a+b)*(b+d))/n AS exp_b,
  ((c+d)*(a+c))/n AS exp_c,
  ((c+d)*(b+d))/n AS exp_d,
  -- Pearson χ²
  (POW(a - ((a+b)*(a+c)/n), 2) / ((a+b)*(a+c)/n)) +
  (POW(b - ((a+b)*(b+d)/n), 2) / ((a+b)*(b+d)/n)) +
  (POW(c - ((c+d)*(a+c)/n), 2) / ((c+d)*(a+c)/n)) +
  (POW(d - ((c+d)*(b+d)/n), 2) / ((c+d)*(b+d)/n)) AS chi_squared
FROM chi;