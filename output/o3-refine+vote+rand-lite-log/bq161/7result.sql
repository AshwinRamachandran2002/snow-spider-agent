-- Net difference between the number of PAAD patients
--   1) with BOTH KRAS and TP53 mutations and
--   2) with NEITHER KRAS nor TP53 mutations
--     (positive result means group‑1 > group‑2)

WITH paad_clinical AS (          -- all PAAD patients in clinical data
  SELECT DISTINCT
         bcr_patient_barcode AS ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE acronym = 'PAAD'
),
paad_mut AS (                    -- PAAD mutation calls (quality‑filtered)
  SELECT DISTINCT
         ParticipantBarcode,
         Hugo_Symbol
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND Hugo_Symbol IN ('KRAS', 'TP53')
),
patient_summary AS (             -- flag each patient for KRAS / TP53 mutation
  SELECT
    c.ParticipantBarcode,
    MAX(CASE WHEN m.Hugo_Symbol = 'KRAS'  THEN 1 ELSE 0 END) AS has_KRAS,
    MAX(CASE WHEN m.Hugo_Symbol = 'TP53'  THEN 1 ELSE 0 END) AS has_TP53
  FROM paad_clinical c
  LEFT JOIN paad_mut m
    ON c.ParticipantBarcode = m.ParticipantBarcode
  GROUP BY c.ParticipantBarcode
)
SELECT
  COUNTIF(has_KRAS = 1 AND has_TP53 = 1)   -- patients mutated in BOTH genes
  -
  COUNTIF(has_KRAS = 0 AND has_TP53 = 0)   -- patients mutated in NEITHER gene
  AS net_difference
FROM patient_summary;