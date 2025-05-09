WITH HighQualityPatients AS (
  SELECT DISTINCT SUBSTRING(m."ParticipantBarcode", 1, 12) AS "PatientBarcode"
  FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
  JOIN PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP" c
    ON SUBSTRING(m."ParticipantBarcode", 1, 12) = c."bcr_patient_barcode"
  LEFT JOIN PANCANCER_ATLAS_2.PANCANCER_ATLAS."MERGED_SAMPLE_QUALITY_ANNOTATIONS" a
    ON m."Tumor_AliquotBarcode" = a."aliquot_barcode"
  WHERE m."Study" = 'PAAD'
    AND m."FILTER" = 'PASS'
    AND c."acronym" = 'PAAD'
    AND (a."Do_not_use" IS NULL OR a."Do_not_use" != 'True')
),
KRAS_Mutations AS (
  SELECT DISTINCT SUBSTRING(m."ParticipantBarcode", 1, 12) AS "PatientBarcode"
  FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
  JOIN PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP" c
    ON SUBSTRING(m."ParticipantBarcode", 1, 12) = c."bcr_patient_barcode"
  LEFT JOIN PANCANCER_ATLAS_2.PANCANCER_ATLAS."MERGED_SAMPLE_QUALITY_ANNOTATIONS" a
    ON m."Tumor_AliquotBarcode" = a."aliquot_barcode"
  WHERE m."Study" = 'PAAD'
    AND m."FILTER" = 'PASS'
    AND m."Hugo_Symbol" = 'KRAS'
    AND c."acronym" = 'PAAD'
    AND (a."Do_not_use" IS NULL OR a."Do_not_use" != 'True')
),
TP53_Mutations AS (
  SELECT DISTINCT SUBSTRING(m."ParticipantBarcode", 1, 12) AS "PatientBarcode"
  FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
  JOIN PANCANCER_ATLAS_2.PANCANCER_ATLAS."FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP" c
    ON SUBSTRING(m."ParticipantBarcode", 1, 12) = c."bcr_patient_barcode"
  LEFT JOIN PANCANCER_ATLAS_2.PANCANCER_ATLAS."MERGED_SAMPLE_QUALITY_ANNOTATIONS" a
    ON m."Tumor_AliquotBarcode" = a."aliquot_barcode"
  WHERE m."Study" = 'PAAD'
    AND m."FILTER" = 'PASS'
    AND m."Hugo_Symbol" = 'TP53'
    AND c."acronym" = 'PAAD'
    AND (a."Do_not_use" IS NULL OR a."Do_not_use" != 'True')
),
Patient_Mutations AS (
  SELECT p."PatientBarcode",
    CASE WHEN k."PatientBarcode" IS NOT NULL THEN 1 ELSE 0 END AS KRAS_mutated,
    CASE WHEN t."PatientBarcode" IS NOT NULL THEN 1 ELSE 0 END AS TP53_mutated
  FROM HighQualityPatients p
  LEFT JOIN KRAS_Mutations k ON p."PatientBarcode" = k."PatientBarcode"
  LEFT JOIN TP53_Mutations t ON p."PatientBarcode" = t."PatientBarcode"
),
Counts AS (
  SELECT 
    SUM(CASE WHEN KRAS_mutated = 1 AND TP53_mutated = 1 THEN 1 ELSE 0 END) AS a,
    SUM(CASE WHEN KRAS_mutated = 1 AND TP53_mutated = 0 THEN 1 ELSE 0 END) AS b,
    SUM(CASE WHEN KRAS_mutated = 0 AND TP53_mutated = 1 THEN 1 ELSE 0 END) AS c,
    SUM(CASE WHEN KRAS_mutated = 0 AND TP53_mutated = 0 THEN 1 ELSE 0 END) AS d,
    COUNT(*) AS N
  FROM Patient_Mutations
),
Expected AS (
  SELECT 
    a,
    b,
    c,
    d,
    N,
    (a + b) AS Row1_Total,
    (c + d) AS Row2_Total,
    (a + c) AS Col1_Total,
    (b + d) AS Col2_Total,
    ((a + b) * (a + c)) / CAST(N AS FLOAT) AS E_a,
    ((a + b) * (b + d)) / CAST(N AS FLOAT) AS E_b,
    ((c + d) * (a + c)) / CAST(N AS FLOAT) AS E_c,
    ((c + d) * (b + d)) / CAST(N AS FLOAT) AS E_d
  FROM Counts
),
Chi_Squared AS (
  SELECT 
    ROUND(
      ((a - E_a)*(a - E_a))/E_a +
      ((b - E_b)*(b - E_b))/E_b +
      ((c - E_c)*(c - E_c))/E_c +
      ((d - E_d)*(d - E_d))/E_d
    ,4) AS "chi-squared value"
  FROM Expected
)
SELECT "chi-squared value" FROM Chi_Squared;