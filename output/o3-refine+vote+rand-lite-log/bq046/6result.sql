/*  Female TCGA‑BRCA patients aged ≤ 30 (without disqualifying annotations)
    and their corresponding GDC file GCS‑URLs from archive release 14          */

WITH clinical_filtered AS (      -- 1) young female BRCA cases
  SELECT DISTINCT
         case_barcode
  FROM   `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE  disease_code = 'BRCA'
    AND  UPPER(gender) = 'FEMALE'
    AND  age_at_diagnosis IS NOT NULL
    AND  age_at_diagnosis <= 30
),

annotation_bad AS (              -- 2) patients that must be excluded
  SELECT DISTINCT
         case_barcode
  FROM   `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE  entity_type = 'Patient'
    AND ( category = 'History of unacceptable prior treatment related to a prior/other malignancy'
          OR classification = 'Redaction' )
),

good_cases AS (                  -- 3) keep only those without bad annotations
  SELECT c.case_barcode
  FROM   clinical_filtered c
  LEFT  JOIN annotation_bad a
         ON c.case_barcode = a.case_barcode
  WHERE  a.case_barcode IS NULL
),

file_ids AS (                    -- 4) release‑14 files whose names start with the case barcode
  SELECT DISTINCT
         g.case_barcode,
         f.file_id
  FROM   good_cases                                   g
  JOIN   `isb-cgc.GDC_metadata.rel14_fileData_current` f
       ON STARTS_WITH(f.file_name, g.case_barcode)    -- file belongs to the case
),

file_urls AS (                   -- 5) map file_id to GCS URL
  SELECT fi.case_barcode,
         u.file_gdc_url
  FROM   file_ids fi
  JOIN   `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` u
       ON fi.file_id = u.file_gdc_id
)

-- 6) final result
SELECT DISTINCT
       case_barcode,
       file_gdc_url
FROM   file_urls
ORDER BY case_barcode;