-- Chi–squared test (2×2) for association between KRAS and TP53 mutations in
-- pancreatic adenocarcinoma (PAAD) TCGA patients
WITH clinical_paads AS (         -- PAAD patients with clinical follow‑up
  SELECT DISTINCT
         bcr_patient_barcode AS ParticipantBarcode
  FROM  `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE acronym = 'PAAD'
),
paad_mut_flags AS (              -- one row / patient with mutation flags
  SELECT
    ParticipantBarcode,
    MAX(CASE WHEN Hugo_Symbol = 'KRAS' THEN 1 ELSE 0 END)  AS KRAS_mut,
    MAX(CASE WHEN Hugo_Symbol = 'TP53' THEN 1 ELSE 0 END) AS TP53_mut
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
  GROUP BY ParticipantBarcode
),
combined AS (                    -- merge clinical cohort with mutation flags
  SELECT
    c.ParticipantBarcode,
    IFNULL(m.KRAS_mut ,0) AS KRAS_mut,
    IFNULL(m.TP53_mut ,0) AS TP53_mut
  FROM clinical_paads c
  LEFT JOIN paad_mut_flags m
  USING(ParticipantBarcode)
),
tbl AS (                         -- contingency‑table counts
  SELECT
    SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS a_both,
    SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS b_kras_only,
    SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS c_tp53_only,
    SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS d_neither
  FROM combined
),
chisq AS (                       -- χ² statistic for 2×2 table
  SELECT
    a_both,
    b_kras_only,
    c_tp53_only,
    d_neither,
    (a_both + b_kras_only + c_tp53_only + d_neither) AS total_N,
    -- χ² = N(ad−bc)² / ((a+b)(c+d)(a+c)(b+d))
    ( (a_both + b_kras_only + c_tp53_only + d_neither)
      * POW( (a_both*d_neither) - (b_kras_only*c_tp53_only) , 2 )
    ) /
    NULLIF(
      (a_both + b_kras_only)
      * (c_tp53_only + d_neither)
      * (a_both + c_tp53_only)
      * (b_kras_only + d_neither), 0
    )  AS chi_squared
  FROM tbl
)
SELECT
  a_both          AS both_KRAS_and_TP53,
  b_kras_only     AS KRAS_only,
  c_tp53_only     AS TP53_only,
  d_neither       AS neither_gene_mutated,
  total_N         AS total_patients,
  chi_squared
FROM chisq;