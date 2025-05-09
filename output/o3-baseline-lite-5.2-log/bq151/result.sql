-- Chi‑squared test of association between KRAS and TP53 mutations
-- in Pancreatic Adenocarcinoma (PAAD) TCGA cohort
WITH
/* -------------------------------------------
   1.  Identify every PAAD patient that has
       clinical follow‑up information
-------------------------------------------- */
paad_patients AS (
  SELECT DISTINCT
         bcr_patient_barcode             AS ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE  acronym = 'PAAD'
),

/* -------------------------------------------
   2.  For each PAAD patient, flag whether at
       least one high‑quality (MC3) KRAS or
       TP53 mutation is present
-------------------------------------------- */
mutation_flags AS (
  SELECT
      ParticipantBarcode,
      MAX(IF(Hugo_Symbol = 'KRAS',  1, 0)) AS KRAS_mut,
      MAX(IF(Hugo_Symbol = 'TP53',  1, 0)) AS TP53_mut
  FROM  `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
  GROUP BY ParticipantBarcode
),

/* -------------------------------------------
   3.  Merge clinical and mutation data so
       every analysed patient has exactly one
       record; patients without a mutation in
       a gene are coded as wild‑type (0)
-------------------------------------------- */
cohort AS (
  SELECT
      p.ParticipantBarcode,
      IFNULL(m.KRAS_mut,  0) AS KRAS_mut,
      IFNULL(m.TP53_mut,  0) AS TP53_mut
  FROM  paad_patients p
  LEFT JOIN mutation_flags m
  USING (ParticipantBarcode)
),

/* -------------------------------------------
   4.  Build the 2×2 contingency table
-------------------------------------------- */
table_counts AS (
  SELECT
    SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS n11, -- KRAS+ / TP53+
    SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS n10, -- KRAS+ / TP53–
    SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS n01, -- KRAS– / TP53+
    SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS n00  -- KRAS– / TP53–
  FROM cohort
),

/* -------------------------------------------
   5.  Compute expected counts & chi‑square
-------------------------------------------- */
chi_sq AS (
  SELECT
    n11, n10, n01, n00,
    (n11 + n10)                         AS row_KRAS_pos,
    (n01 + n00)                         AS row_KRAS_neg,
    (n11 + n01)                         AS col_TP53_pos,
    (n10 + n00)                         AS col_TP53_neg,
    (n11 + n10 + n01 + n00)             AS grand_n
  FROM table_counts
),
final AS (
  SELECT
    n11, n10, n01, n00,
    -- expected frequencies
    (row_KRAS_pos * col_TP53_pos) / grand_n AS e11,
    (row_KRAS_pos * col_TP53_neg) / grand_n AS e10,
    (row_KRAS_neg * col_TP53_pos) / grand_n AS e01,
    (row_KRAS_neg * col_TP53_neg) / grand_n AS e00,
    -- chi‑squared statistic
    (
      POW(n11 - (row_KRAS_pos * col_TP53_pos) / grand_n, 2) / ((row_KRAS_pos * col_TP53_pos) / grand_n) +
      POW(n10 - (row_KRAS_pos * col_TP53_neg) / grand_n, 2) / ((row_KRAS_pos * col_TP53_neg) / grand_n) +
      POW(n01 - (row_KRAS_neg * col_TP53_pos) / grand_n, 2) / ((row_KRAS_neg * col_TP53_pos) / grand_n) +
      POW(n00 - (row_KRAS_neg * col_TP53_neg) / grand_n, 2) / ((row_KRAS_neg * col_TP53_neg) / grand_n)
    ) AS chi_squared_statistic
  FROM chi_sq
)

SELECT *
FROM final;