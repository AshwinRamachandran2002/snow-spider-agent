/*---------------------------------------------------------------------------
  Chi‑square test for association between KRAS and TP53 mutations
  in TCGA pancreatic adenocarcinoma (PAAD) patients
---------------------------------------------------------------------------*/
WITH paad_patients AS (   -- PAAD cases with follow‑up information
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE Study = 'PAAD'
),
mutation_flags AS (       -- high‑quality MC3 mutation calls for KRAS / TP53
  SELECT
    ParticipantBarcode,
    MAX(CASE WHEN Hugo_Symbol = 'KRAS'  THEN 1 ELSE 0 END) AS kras_mut,
    MAX(CASE WHEN Hugo_Symbol = 'TP53'  THEN 1 ELSE 0 END) AS tp53_mut
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND Hugo_Symbol IN ('KRAS','TP53')
  GROUP BY ParticipantBarcode
),
patient_status AS (       -- mutation status for every PAAD patient
  SELECT
    p.ParticipantBarcode,
    IFNULL(m.kras_mut,0) AS kras_mut,
    IFNULL(m.tp53_mut,0) AS tp53_mut
  FROM paad_patients p
  LEFT JOIN mutation_flags m USING (ParticipantBarcode)
),
contingency AS (          -- 2×2 table counts
  SELECT
    SUM(CASE WHEN kras_mut = 1 AND tp53_mut = 1 THEN 1 ELSE 0 END) AS both_mut,
    SUM(CASE WHEN kras_mut = 1 AND tp53_mut = 0 THEN 1 ELSE 0 END) AS kras_only,
    SUM(CASE WHEN kras_mut = 0 AND tp53_mut = 1 THEN 1 ELSE 0 END) AS tp53_only,
    SUM(CASE WHEN kras_mut = 0 AND tp53_mut = 0 THEN 1 ELSE 0 END) AS neither_mut
  FROM patient_status
),
stats AS (                -- row/column totals
  SELECT
    both_mut,
    kras_only,
    tp53_only,
    neither_mut,
    (both_mut + kras_only)                AS kras_total,
    (both_mut + tp53_only)                AS tp53_total,
    (kras_only + neither_mut)             AS non_tp53_total,
    (tp53_only + neither_mut)             AS non_kras_total,
    (both_mut + kras_only + tp53_only + neither_mut) AS total
  FROM contingency
),
chi_sq AS (               -- expected counts & chi‑square statistic
  SELECT
    *,
    (kras_total * tp53_total      ) / total AS exp_both,
    (kras_total * non_tp53_total  ) / total AS exp_kras_only,
    (non_kras_total * tp53_total  ) / total AS exp_tp53_only,
    (non_kras_total * non_tp53_total) / total AS exp_neither
  FROM stats
)
SELECT
  both_mut      AS n_both_mutated,
  kras_only     AS n_KRAS_only,
  tp53_only     AS n_TP53_only,
  neither_mut   AS n_neither_mutated,
  total         AS n_total_PAAD_patients,
  ROUND(
        POW(both_mut    - exp_both      ,2) / exp_both       +
        POW(kras_only   - exp_kras_only ,2) / exp_kras_only  +
        POW(tp53_only   - exp_tp53_only ,2) / exp_tp53_only  +
        POW(neither_mut - exp_neither   ,2) / exp_neither
  ,4)           AS chi_squared_statistic
FROM chi_sq;