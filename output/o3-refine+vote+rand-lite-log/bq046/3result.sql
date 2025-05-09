/* ---------------------------------------------------------------------------
   Female TCGA‑BRCA cases (age ≤ 30 yrs) WITHOUT disqualifying annotations,
   together with every release‑14 GDC file URL that belongs to those cases
--------------------------------------------------------------------------- */
WITH
/* 1. Cases carrying disqualifying annotations ------------------------------ */
flagged_annots AS (
  SELECT DISTINCT
    case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE entity_type = 'Patient'
    AND (
         category = 'History of unacceptable prior treatment related to a prior/other malignancy'
         OR classification = 'Redaction'
        )
),

/* 2. Young female BRCA cases (age ≤ 30) ------------------------------------ */
young_brca AS (
  SELECT DISTINCT
    case_barcode,
    case_gdc_id
  FROM `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE disease_code      = 'BRCA'
    AND UPPER(gender)     = 'FEMALE'
    AND age_at_diagnosis IS NOT NULL
    AND age_at_diagnosis  <= 30
),

/* 3. Remove cases that have a disqualifying annotation ---------------------- */
eligible_cases AS (
  SELECT
    y.case_barcode,
    y.case_gdc_id
  FROM young_brca AS y
  LEFT JOIN flagged_annots AS f
    ON y.case_barcode = f.case_barcode
  WHERE f.case_barcode IS NULL          -- keep only un‑flagged cases
)

/* 4. Retrieve every release‑14 file URL tied to the remaining cases --------- */
SELECT DISTINCT
  ec.case_barcode,
  gcs.file_gdc_url AS gdc_file_url
FROM eligible_cases AS ec
JOIN `isb-cgc.GDC_metadata.rel14_fileData_current` AS fd
  ON fd.case_gdc_id = ec.case_gdc_id            -- file belongs to the case
JOIN `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` AS gcs
  ON gcs.file_gdc_id = fd.file_id
ORDER BY ec.case_barcode;