-- Net difference between PAAD patients mutated in BOTH KRAS & TP53
-- and PAAD patients mutated in NEITHER of these two genes
WITH
-- 1) Every PAAD patient that has follow-up data in the TCGA Clinical Data Resource
all_paad AS (
  SELECT DISTINCT `ParticipantBarcode`
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE `Study` = 'PAAD'
),

-- 2) PAAD patients with a KRAS mutation that passed all filters
kras AS (
  SELECT DISTINCT `ParticipantBarcode`
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE `Study` = 'PAAD'
    AND `Hugo_Symbol` = 'KRAS'
),

-- 3) PAAD patients with a TP53 mutation that passed all filters
tp53 AS (
  SELECT DISTINCT `ParticipantBarcode`
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE `Study` = 'PAAD'
    AND `Hugo_Symbol` = 'TP53'
),

-- 4) Patients mutated in BOTH KRAS AND TP53
both_mutated AS (
  SELECT kras.`ParticipantBarcode`
  FROM kras
  INNER JOIN tp53
  USING (`ParticipantBarcode`)
),

-- 5) Patients mutated in EITHER KRAS OR TP53 (union set)
kras_tp53_any AS (
  SELECT `ParticipantBarcode` FROM kras
  UNION DISTINCT
  SELECT `ParticipantBarcode` FROM tp53
),

-- 6) Patients mutated in NEITHER gene
neither_mutated AS (
  SELECT a.`ParticipantBarcode`
  FROM all_paad a
  LEFT JOIN kras_tp53_any k
    ON a.`ParticipantBarcode` = k.`ParticipantBarcode`
  WHERE k.`ParticipantBarcode` IS NULL
)

-- 7) Final counts and net difference
SELECT
  (SELECT COUNT(*) FROM both_mutated)        AS both_mutated_count,
  (SELECT COUNT(*) FROM neither_mutated)     AS neither_mutated_count,
  (SELECT COUNT(*) FROM both_mutated) -
  (SELECT COUNT(*) FROM neither_mutated)     AS net_difference;