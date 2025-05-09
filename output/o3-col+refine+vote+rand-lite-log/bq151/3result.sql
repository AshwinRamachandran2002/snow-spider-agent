/*  Chi-square test of independence between KRAS and TP53
    mutations in pancreatic adenocarcinoma (PAAD) patients            */

WITH paad_patients AS (         -- master PAAD patient list (clinical CDR)
  SELECT ParticipantBarcode
  FROM  `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE Study = 'PAAD'
),

valid_mutations AS (            -- high-quality somatic mutations (MC3)
  SELECT m.ParticipantBarcode,
         m.Hugo_Symbol
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample` AS m
  LEFT JOIN `isb-cgc-bq.pancancer_atlas.merged_sample_quality_annotations`      AS q
         ON m.Tumor_AliquotBarcode = q.aliquot_barcode
  WHERE  m.Study = 'PAAD'
    AND  (q.Do_not_use IS NULL OR LOWER(q.Do_not_use) = 'false')     -- quality filter
    AND  m.Hugo_Symbol IN ('KRAS','TP53')                            -- genes of interest
),

mutation_flags AS (             -- one row / patient, 0-1 flags for each gene
  SELECT ParticipantBarcode,
         MAX(CASE WHEN Hugo_Symbol = 'KRAS' THEN 1 ELSE 0 END)  AS KRAS_mut,
         MAX(CASE WHEN Hugo_Symbol = 'TP53' THEN 1 ELSE 0 END)  AS TP53_mut
  FROM   valid_mutations
  GROUP BY ParticipantBarcode
),

combined AS (                   -- bring in all PAAD patients (mutated or not)
  SELECT p.ParticipantBarcode,
         COALESCE(m.KRAS_mut,0)  AS KRAS_mut,
         COALESCE(m.TP53_mut,0)  AS TP53_mut
  FROM   paad_patients AS p
  LEFT JOIN mutation_flags AS m USING (ParticipantBarcode)
),

-- 2×2 contingency‐table counts
contingency AS (
  SELECT
    SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS both_mut,
    SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS kras_only,
    SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS tp53_only,
    SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS none
  FROM combined
),

-- add marginal totals & expected counts
expected AS (
  SELECT *,
         (both_mut + kras_only + tp53_only + none)            AS N,
         (both_mut + kras_only)                               AS KRAS_yes,
         (tp53_only + none)                                   AS KRAS_no,
         (both_mut + tp53_only)                               AS TP53_yes,
         (kras_only + none)                                   AS TP53_no
  FROM contingency
),

chi_calc AS (
  SELECT *,
         (KRAS_yes * TP53_yes) / N  AS exp_both,
         (KRAS_yes * TP53_no ) / N  AS exp_kras_only,
         (KRAS_no  * TP53_yes) / N  AS exp_tp53_only,
         (KRAS_no  * TP53_no ) / N  AS exp_none
  FROM expected
)

SELECT
  both_mut, kras_only, tp53_only, none,                       -- observed counts
  exp_both, exp_kras_only, exp_tp53_only, exp_none,           -- expected counts
  -- chi-square statistic with 1 d.f.
  ((both_mut  - exp_both     )*(both_mut  - exp_both     ))/exp_both      +
  ((kras_only - exp_kras_only)*(kras_only - exp_kras_only))/exp_kras_only +
  ((tp53_only - exp_tp53_only)*(tp53_only - exp_tp53_only))/exp_tp53_only +
  ((none      - exp_none     )*(none      - exp_none     ))/exp_none      AS chi_squared_statistic
FROM chi_calc;