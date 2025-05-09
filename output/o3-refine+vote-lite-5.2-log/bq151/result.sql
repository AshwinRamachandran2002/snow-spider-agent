-- Chi‑squared test of association between KRAS and TP53 mutations
-- in TCGA pancreatic adenocarcinoma (PAAD) patients
WITH clinical_paad AS (   -- PAAD patients that possess follow‑up records
  SELECT DISTINCT
    bcr_patient_barcode AS ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE acronym = 'PAAD'
),
high_quality_mut AS (     -- one‑per‑patient high‑quality MC3 mutation calls
  SELECT DISTINCT
    ParticipantBarcode,
    CASE WHEN Hugo_Symbol = 'KRAS'  THEN 1 END AS KRAS_mut,
    CASE WHEN Hugo_Symbol = 'TP53'  THEN 1 END AS TP53_mut
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study  = 'PAAD'
    AND FILTER = 'PASS'              -- retain only high‑quality mutation calls
    AND Hugo_Symbol IN ('KRAS','TP53')
),
mut_flags AS (            -- collapse to one flag per gene, per patient
  SELECT
    ParticipantBarcode,
    MAX(KRAS_mut)  AS KRAS_mut,
    MAX(TP53_mut)  AS TP53_mut
  FROM high_quality_mut
  GROUP BY ParticipantBarcode
),
cohort AS (               -- complete PAAD cohort with mutation flags (0/1)
  SELECT
    c.ParticipantBarcode,
    IFNULL(m.KRAS_mut,0) AS KRAS_mut,
    IFNULL(m.TP53_mut,0) AS TP53_mut
  FROM clinical_paad c
  LEFT JOIN mut_flags m
  USING (ParticipantBarcode)
),
obs_ct AS (               -- observed 2×2 contingency counts
  SELECT
    SUM(CASE WHEN KRAS_mut=1 AND TP53_mut=1 THEN 1 ELSE 0 END) AS n11, -- KRAS+ / TP53+
    SUM(CASE WHEN KRAS_mut=1 AND TP53_mut=0 THEN 1 ELSE 0 END) AS n10, -- KRAS+ / TP53–
    SUM(CASE WHEN KRAS_mut=0 AND TP53_mut=1 THEN 1 ELSE 0 END) AS n01, -- KRAS– / TP53+
    SUM(CASE WHEN KRAS_mut=0 AND TP53_mut=0 THEN 1 ELSE 0 END) AS n00  -- KRAS– / TP53–
  FROM cohort
),
calc AS (                 -- totals & expected cell counts
  SELECT
    n11, n10, n01, n00,
    (n11+n10+n01+n00)                         AS n_tot,
    (n11+n10)                                AS row_KRAS1,
    (n01+n00)                                AS row_KRAS0,
    (n11+n01)                                AS col_TP531,
    (n10+n00)                                AS col_TP530
  FROM obs_ct
),
expected AS (
  SELECT
    *,
    (row_KRAS1*col_TP531)/n_tot AS e11,
    (row_KRAS1*col_TP530)/n_tot AS e10,
    (row_KRAS0*col_TP531)/n_tot AS e01,
    (row_KRAS0*col_TP530)/n_tot AS e00
  FROM calc
),
chi_sq AS (               -- Pearson chi‑squared statistic (1 d.f.)
  SELECT
    n11, n10, n01, n00,
    e11, e10, e01, e00,
    ((n11-e11)*(n11-e11))/e11 +
    ((n10-e10)*(n10-e10))/e10 +
    ((n01-e01)*(n01-e01))/e01 +
    ((n00-e00)*(n00-e00))/e00   AS chi_squared
  FROM expected
)

SELECT
  n11 AS both_mutated,
  n10 AS KRAS_only,
  n01 AS TP53_only,
  n00 AS neither_mutated,
  chi_squared
FROM chi_sq;