WITH paad_patients AS (
  -- all pancreatic adenocarcinoma patients with follow‑up/clinical records
  SELECT DISTINCT
         bcr_patient_barcode AS ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE acronym = 'PAAD'
),
paad_kras_tp53_mut AS (
  -- KRAS or TP53 mutations that passed all MC3 filters in PAAD
  SELECT DISTINCT
         ParticipantBarcode,
         Hugo_Symbol
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND Hugo_Symbol IN ('KRAS','TP53')
),
per_patient_flags AS (
  -- flag each patient for presence/absence of the two mutations
  SELECT
    p.ParticipantBarcode,
    MAX(CASE WHEN m.Hugo_Symbol = 'KRAS' THEN 1 ELSE 0 END)  AS has_KRAS_mut,
    MAX(CASE WHEN m.Hugo_Symbol = 'TP53' THEN 1 ELSE 0 END) AS has_TP53_mut
  FROM paad_patients p
  LEFT JOIN paad_kras_tp53_mut m
         ON p.ParticipantBarcode = m.ParticipantBarcode
  GROUP BY p.ParticipantBarcode
),
summary AS (
  SELECT
    SUM(CASE WHEN has_KRAS_mut = 1 AND has_TP53_mut = 1 THEN 1 ELSE 0 END) AS n_both,
    SUM(CASE WHEN has_KRAS_mut = 0 AND has_TP53_mut = 0 THEN 1 ELSE 0 END) AS n_neither
  FROM per_patient_flags
)
-- net difference = patients mutated in both genes minus patients mutated in neither
SELECT
  n_both - n_neither AS net_difference
FROM summary;