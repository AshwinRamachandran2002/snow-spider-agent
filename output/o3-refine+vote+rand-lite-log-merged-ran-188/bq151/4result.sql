WITH paad_patients AS (  -- all PAAD cases that have clinical follow‑up data
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE Study = 'PAAD'
),

mutation_flags AS (      -- high‑quality mutation calls (MC3, FILTER='PASS')
  SELECT
    ParticipantBarcode,
    MAX(CASE WHEN Hugo_Symbol = 'KRAS'  THEN 1 ELSE 0 END) AS KRAS_mut,
    MAX(CASE WHEN Hugo_Symbol = 'TP53'  THEN 1 ELSE 0 END) AS TP53_mut
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND FILTER = 'PASS'
    AND Hugo_Symbol IN ('KRAS','TP53')
  GROUP BY ParticipantBarcode
),

combined AS (            -- one row per patient, 0/1 flags for each gene
  SELECT
    p.ParticipantBarcode,
    IFNULL(m.KRAS_mut ,0) AS KRAS_mut,
    IFNULL(m.TP53_mut ,0) AS TP53_mut
  FROM paad_patients p
  LEFT JOIN mutation_flags m
  USING (ParticipantBarcode)
),

contingency AS (         -- 2×2 table counts
  SELECT
    SUM(CASE WHEN KRAS_mut=1 AND TP53_mut=1 THEN 1 END) AS both_mut,
    SUM(CASE WHEN KRAS_mut=1 AND TP53_mut=0 THEN 1 END) AS kras_only,
    SUM(CASE WHEN KRAS_mut=0 AND TP53_mut=1 THEN 1 END) AS tp53_only,
    SUM(CASE WHEN KRAS_mut=0 AND TP53_mut=0 THEN 1 END) AS neither
  FROM combined
),

expected AS (            -- expected counts + totals
  SELECT
    both_mut, kras_only, tp53_only, neither,
    (both_mut+kras_only+tp53_only+neither)           AS N,
    (both_mut+kras_only)                            AS KRAS_yes,
    (tp53_only+neither)                             AS KRAS_no,
    (both_mut+tp53_only)                            AS TP53_yes,
    (kras_only+neither)                             AS TP53_no
  FROM contingency
),

chi_sq AS (              -- chi‑squared statistic
  SELECT
    both_mut, kras_only, tp53_only, neither, N,
    -- expected values
    (KRAS_yes*TP53_yes)/N AS E_both,
    (KRAS_yes*TP53_no )/N AS E_kras_only,
    (KRAS_no *TP53_yes)/N AS E_tp53_only,
    (KRAS_no *TP53_no )/N AS E_neither
  FROM expected
)

SELECT
  both_mut        AS patients_both_KRAS_TP53,
  kras_only       AS patients_KRAS_only,
  tp53_only       AS patients_TP53_only,
  neither         AS patients_neither_mutated,
  N               AS total_paad_patients,
  ROUND(          -- χ² = Σ (O‑E)² / E
    ((both_mut  - E_both     )*(both_mut  - E_both     ))/E_both      +
    ((kras_only - E_kras_only)*(kras_only - E_kras_only))/E_kras_only +
    ((tp53_only - E_tp53_only)*(tp53_only - E_tp53_only))/E_tp53_only +
    ((neither   - E_neither  )*(neither   - E_neither  ))/E_neither
  ,4) AS chi_squared_statistic
FROM chi_sq;