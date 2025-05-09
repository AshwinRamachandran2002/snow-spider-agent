WITH paad_patients AS (
   SELECT DISTINCT bcr_patient_barcode AS ParticipantBarcode
   FROM `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
   WHERE acronym = 'PAAD'
),

kras_mutations AS (
   SELECT DISTINCT ParticipantBarcode, 1 AS KRAS_mut
   FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
   WHERE Study = 'PAAD' AND Hugo_Symbol = 'KRAS' AND Variant_Classification NOT IN ('Silent')
),

tp53_mutations AS (
   SELECT DISTINCT ParticipantBarcode, 1 AS TP53_mut
   FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
   WHERE Study = 'PAAD' AND Hugo_Symbol = 'TP53' AND Variant_Classification NOT IN ('Silent')
),

combined AS (
   SELECT
      p.ParticipantBarcode,
      IF(k.KRAS_mut IS NOT NULL, 1, 0) AS KRAS_mut,
      IF(t.TP53_mut IS NOT NULL, 1, 0) AS TP53_mut
   FROM
      paad_patients p
   LEFT JOIN
      kras_mutations k ON p.ParticipantBarcode = k.ParticipantBarcode
   LEFT JOIN
      tp53_mutations t ON p.ParticipantBarcode = t.ParticipantBarcode
),

totals AS (
   SELECT
      SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS n11,
      SUM(CASE WHEN KRAS_mut = 1 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS n10,
      SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 1 THEN 1 ELSE 0 END) AS n01,
      SUM(CASE WHEN KRAS_mut = 0 AND TP53_mut = 0 THEN 1 ELSE 0 END) AS n00,
      COUNT(*) AS N
   FROM
      combined
),

expected AS (
   SELECT
      *,
      (n11 + n10) AS n1_,
      (n01 + n00) AS n0_,
      (n11 + n01) AS n_1,
      (n10 + n00) AS n_0,
      CAST( ( (n11 + n10) * (n11 + n01) ) AS FLOAT64 ) / N AS E11,
      CAST( ( (n11 + n10) * (n10 + n00) ) AS FLOAT64 ) / N AS E10,
      CAST( ( (n01 + n00) * (n11 + n01) ) AS FLOAT64 ) / N AS E01,
      CAST( ( (n01 + n00) * (n10 + n00) ) AS FLOAT64 ) / N AS E00
   FROM totals
),

chi_squared AS (
   SELECT
      ROUND(
         ((n11 - E11)*(n11 - E11))/E11 +
         ((n10 - E10)*(n10 - E10))/E10 +
         ((n01 - E01)*(n01 - E01))/E01 +
         ((n00 - E00)*(n00 - E00))/E00
      , 4) AS chi_squared_value
   FROM expected
)

SELECT chi_squared_value
FROM chi_squared;