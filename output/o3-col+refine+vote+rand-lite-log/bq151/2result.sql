-- Chi-square test of independence between KRAS and TP53 mutations
-- in TCGA pancreatic adenocarcinoma (PAAD) patients
-- (restricted to high-quality MC3 calls, whitelist cases,
--  and patients with follow-up information in the CDR file)

WITH
/* 1.  PAAD cases that have clinical follow-up (CDR) */
paad_clin AS (
  SELECT ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE  Study = 'PAAD'
),

/* 2.  TCGA whitelist patients (high-quality) */
whitelist AS (
  SELECT ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Whitelist_ParticipantBarcodes`
),

/* 3.  Per-patient mutation flags derived from the
       high-quality MC3 mutation set                    */
mut_flags AS (
  SELECT
      ParticipantBarcode,
      -- 1 = at least one non-silent KRAS mutation
      MAX(CASE WHEN Hugo_Symbol = 'KRAS' THEN 1 ELSE 0 END) AS KRAS_mut,
      -- 1 = at least one non-silent TP53 mutation
      MAX(CASE WHEN Hugo_Symbol = 'TP53' THEN 1 ELSE 0 END) AS TP53_mut
  FROM  `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
  GROUP BY ParticipantBarcode
),

/* 4.  Keep only patients that are in the whitelist AND have CDR follow-up */
analysis_set AS (
  SELECT m.*
  FROM   mut_flags  m
  JOIN   whitelist  w  USING (ParticipantBarcode)
  JOIN   paad_clin  c  USING (ParticipantBarcode)
),

/* 5.  2 × 2 contingency table (observed counts) */
obs AS (
  SELECT
    SUM(IF(KRAS_mut = 1 AND TP53_mut = 1, 1, 0)) AS o11,  -- both mutated
    SUM(IF(KRAS_mut = 1 AND TP53_mut = 0, 1, 0)) AS o12,  -- KRAS only
    SUM(IF(KRAS_mut = 0 AND TP53_mut = 1, 1, 0)) AS o21,  -- TP53 only
    SUM(IF(KRAS_mut = 0 AND TP53_mut = 0, 1, 0)) AS o22   -- neither
  FROM analysis_set
),

/* 6.  Expected counts and chi-square statistic */
chi AS (
  SELECT
    o11, o12, o21, o22,
    (o11+o12)                     AS row1,
    (o21+o22)                     AS row2,
    (o11+o21)                     AS col1,
    (o12+o22)                     AS col2,
    (o11+o12+o21+o22)             AS n
  FROM obs
)

SELECT
  -- observed counts
  o11 AS both_mut,
  o12 AS kras_only,
  o21 AS tp53_only,
  o22 AS neither,
  n   AS total_patients,

  -- expected counts under independence
  row1*col1/n AS expected_both,
  row1*col2/n AS expected_kras_only,
  row2*col1/n AS expected_tp53_only,
  row2*col2/n AS expected_neither,

  -- Pearson chi-square statistic (df = 1 for 2 × 2 table)
  ((o11 - row1*col1/n)*(o11 - row1*col1/n))/(row1*col1/n) +
  ((o12 - row1*col2/n)*(o12 - row1*col2/n))/(row1*col2/n) +
  ((o21 - row2*col1/n)*(o21 - row2*col1/n))/(row2*col1/n) +
  ((o22 - row2*col2/n)*(o22 - row2*col2/n))/(row2*col2/n)   AS chi_squared
FROM chi;