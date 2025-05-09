/*------------------------------------------------------------
  Chi‑squared test of independence between KRAS and TP53
  mutations in TCGA Pancreatic Adenocarcinoma (PAAD) patients
  using high‑quality MC3 mutation calls and CDR follow‑up data.
-------------------------------------------------------------*/
WITH
/* 1)  All PAAD patients that passed TCGA quality whitelist    */
paad_patients AS (
  SELECT DISTINCT c.ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`                      AS c
  JOIN `isb-cgc-bq.pancancer_atlas.Whitelist_ParticipantBarcodes` AS w
    ON c.ParticipantBarcode = w.ParticipantBarcode
  WHERE c.Study = 'PAAD'
),

/* 2)  Mutation status per patient for KRAS and TP53            */
gene_mutations AS (
  SELECT
    ParticipantBarcode,
    MAX(CASE WHEN Hugo_Symbol = 'KRAS'  THEN 1 ELSE 0 END) AS KRAS_mut,
    MAX(CASE WHEN Hugo_Symbol = 'TP53'  THEN 1 ELSE 0 END) AS TP53_mut
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND Hugo_Symbol IN ('KRAS','TP53')
  GROUP BY ParticipantBarcode
),

/* 3)  Merge with complete PAAD cohort to capture WT patients   */
mutation_status AS (
  SELECT
    p.ParticipantBarcode,
    COALESCE(m.KRAS_mut,0) AS KRAS_mut,
    COALESCE(m.TP53_mut,0) AS TP53_mut
  FROM paad_patients p
  LEFT JOIN gene_mutations m
    ON p.ParticipantBarcode = m.ParticipantBarcode
),

/* 4)  2×2 contingency‑table counts                            */
contingency AS (
  SELECT
    SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS n11, -- KRAS+ / TP53+
    SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS n10, -- KRAS+ / TP53–
    SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS n01, -- KRAS– / TP53+
    SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS n00  -- KRAS– / TP53–
  FROM mutation_status
),

/* 5)  Compute marginal totals, expected counts & χ² statistic  */
chi2 AS (
  SELECT
    n11, n10, n01, n00,
    (n11 + n10)                       AS r1,   -- KRAS‑mut total
    (n01 + n00)                       AS r0,   -- KRAS‑wt  total
    (n11 + n01)                       AS c1,   -- TP53‑mut total
    (n10 + n00)                       AS c0,   -- TP53‑wt  total
    (n11 + n10 + n01 + n00)           AS N
  FROM contingency
),

result AS (
  SELECT
    n11, n10, n01, n00,
    -- Expected counts
    (r1 * c1) / N AS e11,
    (r1 * c0) / N AS e10,
    (r0 * c1) / N AS e01,
    (r0 * c0) / N AS e00,
    -- Chi‑squared statistic (1 d.f.)
    (POW(n11 - (r1 * c1)/N, 2) / ((r1 * c1)/N)) +
    (POW(n10 - (r1 * c0)/N, 2) / ((r1 * c0)/N)) +
    (POW(n01 - (r0 * c1)/N, 2) / ((r0 * c1)/N)) +
    (POW(n00 - (r0 * c0)/N, 2) / ((r0 * c0)/N)) AS chi_squared_statistic
  FROM chi2
)

SELECT
  n11 AS both_mutated,
  n10 AS kras_only,
  n01 AS tp53_only,
  n00 AS neither_mutated,
  chi_squared_statistic
FROM result;