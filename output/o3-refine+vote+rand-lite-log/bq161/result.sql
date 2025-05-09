-- Net difference between PAAD patients mutated in BOTH KRAS & TP53 
-- and those mutated in NEITHER gene (TCGA, high‑quality “PASS” calls only)

WITH paad_patients AS (               -- all PAAD patients in TCGA clinical data
  SELECT DISTINCT bcr_patient_barcode AS ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE acronym = 'PAAD'
),

kras_tp53_flags AS (                  -- per‑patient mutation flags for KRAS / TP53
  SELECT
    ParticipantBarcode,
    MAX(CASE WHEN Hugo_Symbol = 'KRAS'  THEN 1 ELSE 0 END) AS has_kras,
    MAX(CASE WHEN Hugo_Symbol = 'TP53'  THEN 1 ELSE 0 END) AS has_tp53
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND Hugo_Symbol IN ('KRAS', 'TP53')
    AND FILTER = 'PASS'               -- retain high‑quality calls only
  GROUP BY ParticipantBarcode
),

patient_status AS (                   -- merge flags with full PAAD cohort
  SELECT
    p.ParticipantBarcode,
    COALESCE(f.has_kras, 0)  AS has_kras,
    COALESCE(f.has_tp53, 0)  AS has_tp53
  FROM paad_patients p
  LEFT JOIN kras_tp53_flags f
  ON p.ParticipantBarcode = f.ParticipantBarcode
),

totals AS (                           -- count required patient groups
  SELECT
    SUM(CASE WHEN has_kras = 1 AND has_tp53 = 1 THEN 1 ELSE 0 END) AS both_mut,
    SUM(CASE WHEN has_kras = 0 AND has_tp53 = 0 THEN 1 ELSE 0 END) AS neither_mut
  FROM patient_status
)

SELECT
  both_mut - neither_mut AS net_difference
FROM totals;