/*  Chi-square test for association between KRAS and TP53 mutations
    in pancreatic adenocarcinoma (PAAD) TCGA patients                */

WITH
-- 1)  Un-redacted PAAD patients from the TCGA Clinical Data Resource
cdr AS (
  SELECT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE Study = 'PAAD'
    AND Redaction IS NULL
),

-- 2)  PAAD patients with ≥1 KRAS mutation (high-quality MC-3 calls)
kras_mut AS (
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND Hugo_Symbol = 'KRAS'
),

-- 3)  PAAD patients with ≥1 TP53 mutation (high-quality MC-3 calls)
tp53_mut AS (
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND Hugo_Symbol = 'TP53'
),

-- 4)  Create binary mutation flags for every eligible patient
flags AS (
  SELECT
    cdr.ParticipantBarcode,
    IF(kras_mut.ParticipantBarcode IS NOT NULL, 1, 0) AS KRAS_flag,
    IF(tp53_mut.ParticipantBarcode IS NOT NULL, 1, 0) AS TP53_flag
  FROM cdr
  LEFT JOIN kras_mut ON cdr.ParticipantBarcode = kras_mut.ParticipantBarcode
  LEFT JOIN tp53_mut ON cdr.ParticipantBarcode = tp53_mut.ParticipantBarcode
),

-- 5)  Build the 2×2 contingency table counts
agg AS (
  SELECT
    SUM(CASE WHEN KRAS_flag = 1 AND TP53_flag = 1 THEN 1 ELSE 0 END) AS both_mut,
    SUM(CASE WHEN KRAS_flag = 1 AND TP53_flag = 0 THEN 1 ELSE 0 END) AS kras_only,
    SUM(CASE WHEN KRAS_flag = 0 AND TP53_flag = 1 THEN 1 ELSE 0 END) AS tp53_only,
    SUM(CASE WHEN KRAS_flag = 0 AND TP53_flag = 0 THEN 1 ELSE 0 END) AS neither,
    SUM(KRAS_flag)                                                    AS total_kras,
    SUM(TP53_flag)                                                    AS total_tp53,
    COUNT(*)                                                          AS total_patients
  FROM flags
)

-- 6)  Expected counts under independence & chi-square statistic
SELECT
  both_mut      AS observed_both,
  kras_only     AS observed_kras_only,
  tp53_only     AS observed_tp53_only,
  neither       AS observed_neither,
  total_patients,

  -- expected values
  (total_kras * total_tp53) / total_patients                                           AS expected_both,
  (total_kras * (total_patients - total_tp53)) / total_patients                        AS expected_kras_only,
  ((total_patients - total_kras) * total_tp53) / total_patients                        AS expected_tp53_only,
  ((total_patients - total_kras) * (total_patients - total_tp53)) / total_patients     AS expected_neither,

  -- chi-square statistic (df = 1)
  (POWER(both_mut  - (total_kras * total_tp53) / total_patients, 2) /
        ((total_kras * total_tp53) / total_patients))                                   +
  (POWER(kras_only - (total_kras * (total_patients - total_tp53)) / total_patients, 2) /
        ((total_kras * (total_patients - total_tp53)) / total_patients))               +
  (POWER(tp53_only - ((total_patients - total_kras) * total_tp53) / total_patients, 2) /
        (((total_patients - total_kras) * total_tp53) / total_patients))               +
  (POWER(neither   - ((total_patients - total_kras) * (total_patients - total_tp53)) /
        total_patients, 2) /
        (((total_patients - total_kras) * (total_patients - total_tp53)) / total_patients))
  AS chi_squared_statistic
FROM agg;