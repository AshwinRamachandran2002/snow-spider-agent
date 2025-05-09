WITH paad_patients AS (
  SELECT DISTINCT bcr_patient_barcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE acronym = 'PAAD'
),
mutations AS (
  SELECT DISTINCT m.ParticipantBarcode, m.Hugo_Symbol
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample` AS m
  JOIN paad_patients AS p
    ON m.ParticipantBarcode = p.bcr_patient_barcode
  WHERE m.Hugo_Symbol IN ('KRAS', 'TP53') AND m.FILTER = 'PASS'
),
mutation_counts AS (
  SELECT ParticipantBarcode,
    COUNT(DISTINCT Hugo_Symbol) AS mutated_genes_count
  FROM mutations
  GROUP BY ParticipantBarcode
),
paad_mutations AS (
  SELECT p.bcr_patient_barcode AS ParticipantBarcode,
    IFNULL(mc.mutated_genes_count, 0) AS mutated_genes_count
  FROM paad_patients AS p
  LEFT JOIN mutation_counts AS mc
    ON p.bcr_patient_barcode = mc.ParticipantBarcode
)
SELECT
  (SUM(CASE WHEN mutated_genes_count = 2 THEN 1 ELSE 0 END) -
   SUM(CASE WHEN mutated_genes_count = 0 THEN 1 ELSE 0 END)) AS difference
FROM paad_mutations;