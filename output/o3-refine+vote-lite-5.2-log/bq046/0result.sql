/*  Female (≤30 yrs) BRCA cases – file URLs (GDC release 14)            */

WITH  /* ------------------------------------------------------------------ */
-- 1)  Patients having dis‑qualifying annotations (to be excluded)
bad_patients AS (
  SELECT DISTINCT case_barcode
  FROM  `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE entity_type = 'Patient'
    AND (
         category       = 'History of unacceptable prior treatment related to a prior/other malignancy'
      OR classification = 'Redaction'
    )
),

-- 2)  Eligible BRCA cases: female, age ≤ 30
good_clin AS (
  SELECT
    case_barcode,
    case_gdc_id
  FROM `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE UPPER(disease_code)   = 'BRCA'
    AND UPPER(gender)         = 'FEMALE'
    AND age_at_diagnosis IS NOT NULL
    AND age_at_diagnosis      <= 30
),

-- 3)  Remove patients that appear in the bad‑patient list
valid_cases AS (
  SELECT DISTINCT
    c.case_barcode,
    c.case_gdc_id
  FROM good_clin c
  LEFT JOIN bad_patients b
    ON c.case_barcode = b.case_barcode
  WHERE b.case_barcode IS NULL          -- keep only if NO bad annotation
),

-- 4)  Collect file UUIDs from release‑14 “current” files
/*      The release‑14 table has no direct case‑UUID column, so we link by
        the case barcode prefix that appears at the start of file_name or
        file_submitter_id.                                                 */
case_files AS (
  SELECT DISTINCT
    v.case_barcode,
    f.file_id
  FROM valid_cases v
  JOIN `isb-cgc.GDC_metadata.rel14_fileData_current` f
    ON  ( REGEXP_CONTAINS(f.file_name         , CONCAT('^', v.case_barcode))
       OR REGEXP_CONTAINS(f.file_submitter_id , CONCAT('^', v.case_barcode)) )
    AND f.file_id IS NOT NULL
),

-- 5)  Map file UUIDs to their GCS URLs (release 14 URL table)
urls AS (
  SELECT DISTINCT
    cf.case_barcode,
    u.file_gdc_url
  FROM case_files cf
  JOIN `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` u
    ON u.file_gdc_id = cf.file_id
)

-- Final result -----------------------------------------------------------
SELECT
  case_barcode,
  file_gdc_url
FROM urls
ORDER BY case_barcode;