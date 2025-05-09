-- Net difference between PAAD patients with BOTH KRAS & TP53 mutations 
-- and those with NEITHER mutation (PAAD, high‑quality MC3 calls)

WITH paad_clin AS (
  -- all PAAD patients that have clinical / follow‑up information
  SELECT DISTINCT
         bcr_patient_barcode AS ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE acronym = 'PAAD'
),

paad_mut AS (
  -- mutation status per patient for KRAS and TP53 (quality‑filtered MC3)
  SELECT
    ParticipantBarcode,
    MAX(CASE WHEN Hugo_Symbol = 'KRAS'  THEN 1 ELSE 0 END) AS has_KRAS,
    MAX(CASE WHEN Hugo_Symbol = 'TP53'  THEN 1 ELSE 0 END) AS has_TP53
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
  GROUP BY ParticipantBarcode
),

merged AS (
  -- bring every PAAD patient, assign 0/1 flags (missing → 0)
  SELECT
    c.ParticipantBarcode,
    IFNULL(m.has_KRAS, 0)  AS has_KRAS,
    IFNULL(m.has_TP53, 0)  AS has_TP53
  FROM paad_clin c
  LEFT JOIN paad_mut m
  USING (ParticipantBarcode)
),

counts AS (
  SELECT
    SUM(CASE WHEN has_KRAS = 1 AND has_TP53 = 1 THEN 1 ELSE 0 END) AS n_both_mut,
    SUM(CASE WHEN has_KRAS = 0 AND has_TP53 = 0 THEN 1 ELSE 0 END) AS n_neither_mut
  FROM merged
)

SELECT
  n_both_mut - n_neither_mut AS net_difference
FROM counts;