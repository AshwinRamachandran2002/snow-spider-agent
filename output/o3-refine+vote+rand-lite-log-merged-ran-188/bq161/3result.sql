WITH paad_patients AS (
  -- all PAAD patients with clinical follow‑up data
  SELECT DISTINCT bcr_patient_barcode AS ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE acronym = 'PAAD'
),
mut_flags AS (
  -- mutation flags for KRAS and TP53, using quality‑filtered MC3 MAF
  SELECT
    ParticipantBarcode,
    MAX(CASE WHEN Hugo_Symbol = 'KRAS'  THEN 1 ELSE 0 END) AS KRAS_mut,
    MAX(CASE WHEN Hugo_Symbol = 'TP53'  THEN 1 ELSE 0 END) AS TP53_mut
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND Hugo_Symbol IN ('KRAS','TP53')
  GROUP BY ParticipantBarcode
),
patient_status AS (
  -- merge flags with full patient list; missing → 0 (no mutation recorded)
  SELECT
    p.ParticipantBarcode,
    IFNULL(m.KRAS_mut, 0)  AS KRAS_mut,
    IFNULL(m.TP53_mut, 0)  AS TP53_mut
  FROM paad_patients p
  LEFT JOIN mut_flags m
  ON p.ParticipantBarcode = m.ParticipantBarcode
),
summary AS (
  SELECT
    SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS both_mut,
    SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS neither_mut
  FROM patient_status
)
-- net difference = patients with both mutations minus patients with neither mutation
SELECT
  both_mut - neither_mut AS net_difference
FROM summary;