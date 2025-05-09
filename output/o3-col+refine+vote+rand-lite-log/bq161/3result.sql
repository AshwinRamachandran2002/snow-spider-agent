WITH paad_patients AS (
  -- all PAAD patients with clinical records
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE Study = 'PAAD'
),
kras_mut AS (
  -- PAAD patients mutated in KRAS
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND Hugo_Symbol = 'KRAS'
),
tp53_mut AS (
  -- PAAD patients mutated in TP53
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND Hugo_Symbol = 'TP53'
),
both_mut AS (
  -- patients harbouring mutations in BOTH genes
  SELECT k.ParticipantBarcode
  FROM kras_mut k
  JOIN tp53_mut t
  USING (ParticipantBarcode)
),
neither_mut AS (
  -- PAAD patients with NO mutation in either KRAS or TP53
  SELECT p.ParticipantBarcode
  FROM paad_patients p
  WHERE p.ParticipantBarcode NOT IN (
        SELECT ParticipantBarcode FROM kras_mut
        UNION DISTINCT
        SELECT ParticipantBarcode FROM tp53_mut
  )
)
-- net difference: (both-mutated) − (neither-mutated)
SELECT
  (SELECT COUNT(*) FROM both_mut) -
  (SELECT COUNT(*) FROM neither_mut) AS net_difference;