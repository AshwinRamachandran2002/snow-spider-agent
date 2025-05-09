--  Female BRCA patients  ≤ 30 y without the flagged annotations
--  and the GDC URLs of any files that belong to those cases
--  (GDC metadata release 14).

WITH annotated_cases AS (               -- 1. patients that must be excluded
  SELECT DISTINCT case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE entity_type = 'Patient'
    AND ( category       = 'History of unacceptable prior treatment related to a prior/other malignancy'
          OR classification = 'Redaction' )
),

young_female_brca AS (                  -- 2. clinical filter (age ≤ 30 y)
  SELECT DISTINCT case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE disease_code      = 'BRCA'
    AND gender            = 'FEMALE'
    AND age_at_diagnosis IS NOT NULL
    AND age_at_diagnosis/365.25 <= 30      -- convert days → years
),

eligible_cases AS (                     -- 3. keep only cases NOT in annotation list
  SELECT y.case_barcode
  FROM young_female_brca AS y
  LEFT JOIN annotated_cases AS a
    ON y.case_barcode = a.case_barcode
  WHERE a.case_barcode IS NULL
),

case_files AS (                         -- 4. map cases → file UUIDs (rel14)
  SELECT
    SUBSTR(fd.file_name,1,12) AS case_barcode,   -- TCGA-barcode from filename
    fd.file_gdc_id
  FROM `isb-cgc.GDC_metadata.rel14_fileData_current` AS fd
),

urls AS (                               -- 5. file UUID → GCS URL (rel14)
  SELECT file_gdc_id, file_gdc_url
  FROM `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW`
)

-- 6. final list of barcodes and their file URLs
SELECT DISTINCT
  ec.case_barcode,
  u.file_gdc_url
FROM eligible_cases          AS ec
JOIN case_files              AS f  ON f.case_barcode = ec.case_barcode
JOIN urls                    AS u  ON u.file_gdc_id = f.file_gdc_id
JOIN `isb-cgc.GDC_metadata.rel14_caseData` AS cd      -- ensures case exists in rel14
     ON cd.case_barcode = ec.case_barcode
ORDER BY ec.case_barcode;