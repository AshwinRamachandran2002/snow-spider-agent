-- Find GDC file URLs for un-flagged female BRCA patients (≤ 30 yrs) in TCGA
WITH flagged AS (
  -- Patients that should be excluded
  SELECT DISTINCT case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE entity_type = 'Patient'
    AND (
         category       = 'History of unacceptable prior treatment related to a prior/other malignancy'
      OR classification = 'Redaction'
    )
),
eligible AS (
  -- Female BRCA patients aged 30 or younger
  SELECT DISTINCT case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE disease_code       = 'BRCA'
    AND gender             = 'FEMALE'
    AND age_at_diagnosis  <= 30
),
clean_cases AS (
  -- Remove flagged patients
  SELECT e.case_barcode
  FROM   eligible e
  LEFT JOIN flagged f
  ON     e.case_barcode = f.case_barcode
  WHERE  f.case_barcode IS NULL
),
file_ids AS (
  -- Map case_barcode → file UUIDs in release-14 metadata
  SELECT DISTINCT
         SUBSTR(file_name, 1, 12) AS case_barcode,
         file_gdc_id
  FROM `isb-cgc.GDC_metadata.rel14_fileData_current`
),
urls AS (
  -- UUID → GCS URL
  SELECT file_gdc_id,
         file_gdc_url            -- column holds the full gs:// link
  FROM `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW`
)
SELECT DISTINCT
       c.case_barcode,
       u.file_gdc_url
FROM   clean_cases c
JOIN   file_ids   f  ON c.case_barcode = f.case_barcode
JOIN   urls       u  ON f.file_gdc_id  = u.file_gdc_id
ORDER BY c.case_barcode;