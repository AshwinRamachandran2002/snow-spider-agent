WITH paad_all AS (
  -- all PAAD patients with clinical data
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE Study = 'PAAD'
),
paad_kras AS (
  -- PAAD patients with a PASS-filtered KRAS mutation
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND Hugo_Symbol = 'KRAS'
    AND FILTER = 'PASS'
),
paad_tp53 AS (
  -- PAAD patients with a PASS-filtered TP53 mutation
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND Hugo_Symbol = 'TP53'
    AND FILTER = 'PASS'
),
both_mutated AS (
  -- patients mutated in BOTH KRAS and TP53
  SELECT k.ParticipantBarcode
  FROM paad_kras k
  INNER JOIN paad_tp53 USING (ParticipantBarcode)
),
any_mutated AS (
  -- patients mutated in EITHER gene
  SELECT ParticipantBarcode FROM paad_kras
  UNION DISTINCT
  SELECT ParticipantBarcode FROM paad_tp53
),
neither_mutated AS (
  -- patients mutated in NEITHER gene
  SELECT a.ParticipantBarcode
  FROM paad_all a
  LEFT JOIN any_mutated m
  USING (ParticipantBarcode)
  WHERE m.ParticipantBarcode IS NULL
)
SELECT
  (SELECT COUNT(*) FROM both_mutated)   AS both_mutated_count,
  (SELECT COUNT(*) FROM neither_mutated) AS neither_mutated_count,
  (SELECT COUNT(*) FROM both_mutated) -
  (SELECT COUNT(*) FROM neither_mutated) AS net_difference ;