/* --------------------------------------------------------------------------
   Breast-Cancer (BRCA) female patients aged ≤30 y, **excluding** any case
   that is flagged for prior-treatment or redaction, and returning every
   GDC file URL (release-14) that belongs to those un-flagged patients.
--------------------------------------------------------------------------- */
WITH flagged AS (      -- 1.  All disqualifying TCGA cases
  SELECT DISTINCT
    case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE entity_type = 'Patient'
    AND ( category       = 'History of unacceptable prior treatment related to a prior/other malignancy'
          OR classification = 'Redaction' )
),
young_brca AS (        -- 2.  Female BRCA cases diagnosed at ≤30 years
  SELECT DISTINCT
    case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE disease_code      = 'BRCA'
    AND gender            = 'FEMALE'
    AND age_at_diagnosis IS NOT NULL
    AND age_at_diagnosis  <= 30
),
eligible AS (          -- 3.  Keep only the un-flagged young-BRCA cases
  SELECT y.case_barcode
  FROM   young_brca y
  LEFT JOIN flagged f USING (case_barcode)
  WHERE  f.case_barcode IS NULL          -- remove any flagged patient
)
-- 4.  Map each eligible case to every GDC file and its GCS URL (release-14)
SELECT DISTINCT
  e.case_barcode,
  g.file_gdc_url
FROM eligible                                          AS e
JOIN `isb-cgc.GDC_metadata.rel14_fileData_current`     AS fd
  ON fd.file_name LIKE CONCAT(e.case_barcode, '%')     -- file belongs to case
JOIN `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` AS g
  ON g.file_gdc_id = fd.file_gdc_id
ORDER BY
  e.case_barcode,
  g.file_gdc_url;