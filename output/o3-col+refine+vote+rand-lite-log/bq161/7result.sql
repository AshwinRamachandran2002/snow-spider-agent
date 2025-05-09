WITH paad_clinical AS (
  -- all PAAD patients with clinical follow-up data
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE Study = 'PAAD'
),
paad_mutations AS (
  -- PAAD patients carrying a KRAS or TP53 mutation
  SELECT DISTINCT ParticipantBarcode, Hugo_Symbol
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND Hugo_Symbol IN ('KRAS','TP53')
),
both AS (
  -- patients with mutations in BOTH genes
  SELECT ParticipantBarcode
  FROM paad_mutations
  GROUP BY ParticipantBarcode
  HAVING COUNT(DISTINCT Hugo_Symbol) = 2
),
neither AS (
  -- patients with mutations in NEITHER gene
  SELECT pc.ParticipantBarcode
  FROM paad_clinical pc
  LEFT JOIN paad_mutations pm
    ON pc.ParticipantBarcode = pm.ParticipantBarcode
  WHERE pm.ParticipantBarcode IS NULL
)
SELECT
  (SELECT COUNT(*) FROM both)   AS n_both_mut,
  (SELECT COUNT(*) FROM neither) AS n_neither_mut,
  (SELECT COUNT(*) FROM both) - (SELECT COUNT(*) FROM neither) AS net_difference;