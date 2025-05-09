/* Net difference between PAAD patients with BOTH KRAS & TP53 mutations
   (quality‑filtered) and those with NEITHER mutation                  */

WITH paad_patients AS (
  /* all pancreatic ductal adenocarcinoma (PAAD) patients in TCGA      */
  SELECT DISTINCT
         bcr_patient_barcode AS ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE  acronym = 'PAAD'
),
kras_mut AS (
  /* PAAD patients whose tumours carry a high‑quality KRAS mutation    */
  SELECT DISTINCT
         ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE  Study          = 'PAAD'
    AND  Hugo_Symbol    = 'KRAS'
    AND  FILTER         = 'PASS'
),
tp53_mut AS (
  /* PAAD patients whose tumours carry a high‑quality TP53 mutation    */
  SELECT DISTINCT
         ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE  Study          = 'PAAD'
    AND  Hugo_Symbol    = 'TP53'
    AND  FILTER         = 'PASS'
),
mutation_status AS (
  /* map every PAAD patient to mutation status for the two genes       */
  SELECT
    p.ParticipantBarcode,
    IF(k.ParticipantBarcode IS NULL, 0, 1) AS has_KRAS,
    IF(t.ParticipantBarcode IS NULL, 0, 1) AS has_TP53
  FROM paad_patients p
  LEFT JOIN kras_mut k USING (ParticipantBarcode)
  LEFT JOIN tp53_mut t USING (ParticipantBarcode)
)
SELECT
  SUM(CASE WHEN has_KRAS = 1 AND has_TP53 = 1 THEN 1 ELSE 0 END)     AS patients_with_both,
  SUM(CASE WHEN has_KRAS = 0 AND has_TP53 = 0 THEN 1 ELSE 0 END)     AS patients_with_neither,
  SUM(CASE WHEN has_KRAS = 1 AND has_TP53 = 1 THEN 1 ELSE 0 END)
  -
  SUM(CASE WHEN has_KRAS = 0 AND has_TP53 = 0 THEN 1 ELSE 0 END)     AS net_difference
FROM mutation_status;