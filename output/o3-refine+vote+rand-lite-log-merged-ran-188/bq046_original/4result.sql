/*  Female TCGA‑BRCA patients (≤ 30 yrs) who have NO disqualifying annotations
    and the URLs of all their files from GDC release 14                       */

WITH flagged AS (          -- cases carrying disqualifying annotations
  SELECT DISTINCT
         COALESCE(case_barcode, entity_barcode) AS case_barcode,
         case_gdc_id
  FROM `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE LOWER(entity_type) = 'patient'
    AND (
          category = 'History of unacceptable prior treatment related to a prior/other malignancy'
          OR classification = 'Redaction'
        )
),

brca30 AS (                -- female BRCA patients 30 yrs old or younger
  SELECT DISTINCT
         case_barcode,
         case_gdc_id
  FROM `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE disease_code = 'BRCA'
    AND UPPER(gender) = 'FEMALE'
    AND age_at_diagnosis IS NOT NULL
    AND age_at_diagnosis <= 30
),

eligible_cases AS (        -- keep only cases that are NOT flagged
  SELECT
         b.case_barcode,
         b.case_gdc_id
  FROM brca30 b
  LEFT JOIN flagged f
    ON b.case_barcode = f.case_barcode
  WHERE f.case_barcode IS NULL
),

case_files AS (            -- map eligible cases to file UUIDs (release 14)
  SELECT DISTINCT
         e.case_barcode,
         fd.file_id
  FROM eligible_cases e
  JOIN `isb-cgc.GDC_metadata.rel14_fileData_current` fd
    ON fd.associated_entities__case_gdc_id = e.case_gdc_id   -- link via case UUID
),

case_urls AS (             -- attach GCS URLs
  SELECT DISTINCT
         cf.case_barcode,
         url.file_gdc_url
  FROM case_files cf
  JOIN `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` url
    ON url.file_gdc_id = cf.file_id
)

SELECT
  case_barcode,
  file_gdc_url
FROM case_urls
ORDER BY case_barcode;