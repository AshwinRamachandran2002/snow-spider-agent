-- Task: Using the TCGA dataset, compute the chi-squared statistic to evaluate the association between KRAS and TP53 gene mutations in patients diagnosed with pancreatic adenocarcinoma (PAAD). Select unique patients with PAAD from the clinical follow-up data ("FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP" table). For these patients, determine whether they have mutations in the KRAS and TP53 genes using high-quality mutation annotations (from "FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" table where "FILTER" = 'PASS' and "Study" = 'PAAD'). Match patient records based on "bcr_patient_barcode". Calculate the counts of patients with combinations of KRAS and TP53 mutations: both mutations, KRAS only, TP53 only, neither mutation. Use these counts to compute the chi-squared statistic to assess the association between KRAS and TP53 mutations in the PAAD patient population. Return the chi-squared statistic rounded to four decimal places.
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
),
counts AS (
  SELECT
    SUM(CASE WHEN KRAS_mutation = 1 AND TP53_mutation = 1 THEN 1 ELSE 0 END) AS A,
    SUM(CASE WHEN KRAS_mutation = 1 AND TP53_mutation = 0 THEN 1 ELSE 0 END) AS B,
    SUM(CASE WHEN KRAS_mutation = 0 AND TP53_mutation = 1 THEN 1 ELSE 0 END) AS C,
    SUM(CASE WHEN KRAS_mutation = 0 AND TP53_mutation = 0 THEN 1 ELSE 0 END) AS D
  FROM mutations
),
expected AS (
  SELECT
    A, B, C, D,
    (A + B + C + D) AS N,
    (A + B) AS Row1_Total,
    (C + D) AS Row2_Total,
    (A + C) AS Col1_Total,
    (B + D) AS Col2_Total,
    ((A + C) * (A + B))::FLOAT / NULLIF((A + B + C + D), 0) AS E11,
    ((B + D) * (A + B))::FLOAT / NULLIF((A + B + C + D), 0) AS E12,
    ((A + C) * (C + D))::FLOAT / NULLIF((A + B + C + D), 0) AS E21,
    ((B + D) * (C + D))::FLOAT / NULLIF((A + B + C + D), 0) AS E22
  FROM counts
),
chi_squared AS (
  SELECT
    ((A - E11)*(A - E11)) / NULLIF(E11, 0) +
    ((B - E12)*(B - E12)) / NULLIF(E12, 0) +
    ((C - E21)*(C - E21)) / NULLIF(E21, 0) +
    ((D - E22)*(D - E22)) / NULLIF(E22, 0) AS chi_squared_value
  FROM expected
)
SELECT ROUND(chi_squared_value, 4) AS "chi-squared value"
FROM chi_squared;