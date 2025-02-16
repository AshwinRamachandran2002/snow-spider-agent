-- Task: Using the TCGA dataset, find the number of pancreatic adenocarcinoma (PAAD) patients with mutations in KRAS, TP53, both, and neither, considering high-quality mutation annotations and ensuring accurate patient matching.
WITH patients AS (
  SELECT DISTINCT p."bcr_patient_barcode"
  FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP AS p
  WHERE p."acronym" = 'PAAD'
),
mutations AS (
  SELECT
    p."bcr_patient_barcode",
    MAX(CASE WHEN m."Hugo_Symbol" = 'KRAS' THEN 1 ELSE 0 END) AS KRAS_mutation,
    MAX(CASE WHEN m."Hugo_Symbol" = 'TP53' THEN 1 ELSE 0 END) AS TP53_mutation
  FROM patients p
  LEFT JOIN PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE AS m
    ON p."bcr_patient_barcode" = m."ParticipantBarcode"
    AND m."Study" = 'PAAD'
    AND m."Hugo_Symbol" IN ('KRAS', 'TP53')
    AND m."FILTER" = 'PASS'
  GROUP BY p."bcr_patient_barcode"
)
SELECT
  SUM(CASE WHEN KRAS_mutation = 1 AND TP53_mutation = 1 THEN 1 ELSE 0 END) AS "Both_Mutations",
  SUM(CASE WHEN KRAS_mutation = 1 AND TP53_mutation = 0 THEN 1 ELSE 0 END) AS "KRAS_only",
  SUM(CASE WHEN KRAS_mutation = 0 AND TP53_mutation = 1 THEN 1 ELSE 0 END) AS "TP53_only",
  SUM(CASE WHEN KRAS_mutation = 0 AND TP53_mutation = 0 THEN 1 ELSE 0 END) AS "Neither_Mutation"
FROM mutations;