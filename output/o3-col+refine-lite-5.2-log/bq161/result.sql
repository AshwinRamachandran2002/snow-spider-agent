WITH paad_patients AS (
  -- all PAAD patients with clinical follow‑up records
  SELECT DISTINCT `ParticipantBarcode`
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE `Study` = 'PAAD'
),
kras_mut AS (
  -- PAAD patients with a KRAS mutation (MC3 filtered)
  SELECT DISTINCT `ParticipantBarcode`
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE `Study` = 'PAAD'
    AND `Hugo_Symbol` = 'KRAS'
),
tp53_mut AS (
  -- PAAD patients with a TP53 mutation (MC3 filtered)
  SELECT DISTINCT `ParticipantBarcode`
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE `Study` = 'PAAD'
    AND `Hugo_Symbol` = 'TP53'
),
both_mut AS (
  -- patients carrying BOTH mutations
  SELECT k.`ParticipantBarcode`
  FROM kras_mut k
  INNER JOIN tp53_mut t
  ON k.`ParticipantBarcode` = t.`ParticipantBarcode`
),
either_mut AS (
  -- patients carrying EITHER mutation
  SELECT `ParticipantBarcode` FROM kras_mut
  UNION DISTINCT
  SELECT `ParticipantBarcode` FROM tp53_mut
),
neither_mut AS (
  -- PAAD patients with NEITHER mutation
  SELECT p.`ParticipantBarcode`
  FROM paad_patients p
  LEFT JOIN either_mut e
  ON p.`ParticipantBarcode` = e.`ParticipantBarcode`
  WHERE e.`ParticipantBarcode` IS NULL
)
SELECT
  (SELECT COUNT(*) FROM both_mut)   AS with_both_mutations,
  (SELECT COUNT(*) FROM neither_mut) AS with_neither_mutations,
  (SELECT COUNT(*) FROM both_mut) - 
  (SELECT COUNT(*) FROM neither_mut) AS net_difference;