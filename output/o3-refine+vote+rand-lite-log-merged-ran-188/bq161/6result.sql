WITH paad_patients AS (
  -- all PAAD patients having clinical records in TCGA
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE Study = 'PAAD'
),
paad_mut_flags AS (
  -- for every PAAD patient, mark if KRAS and/or TP53 mutations are present
  SELECT
    ParticipantBarcode,
    MAX(CASE WHEN UPPER(Hugo_Symbol) = 'KRAS'  THEN 1 ELSE 0 END) AS has_kras,
    MAX(CASE WHEN UPPER(Hugo_Symbol) = 'TP53'  THEN 1 ELSE 0 END) AS has_tp53
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
  GROUP BY ParticipantBarcode
),
merged AS (
  -- left‑join so patients without any mutation rows get flags = 0
  SELECT
    p.ParticipantBarcode,
    IFNULL(m.has_kras, 0) AS has_kras,
    IFNULL(m.has_tp53, 0) AS has_tp53
  FROM paad_patients p
  LEFT JOIN paad_mut_flags m
  ON p.ParticipantBarcode = m.ParticipantBarcode
),
counts AS (
  SELECT
    SUM(CASE WHEN has_kras = 1 AND has_tp53 = 1 THEN 1 ELSE 0 END) AS patients_with_both,
    SUM(CASE WHEN has_kras = 0 AND has_tp53 = 0 THEN 1 ELSE 0 END) AS patients_with_none
  FROM merged
)
SELECT
  patients_with_both - patients_with_none AS net_difference
FROM counts;