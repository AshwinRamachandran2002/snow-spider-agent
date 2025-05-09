/*  Case barcodes (female, ≤30 yrs, BRCA) that have no disqualifying
    annotation, together with all of their GDC file URLs
*/
WITH flagged AS (
  SELECT DISTINCT case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE entity_type = 'Patient'
    AND (category = 'History of unacceptable prior treatment related to a prior/other malignancy'
         OR classification = 'Redaction')
),
young_female_brca AS (
  SELECT DISTINCT case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE disease_code = 'BRCA'
    AND gender = 'FEMALE'
    AND age_at_diagnosis IS NOT NULL
    AND age_at_diagnosis <= 30
),
eligible_cases AS (     -- keep only if NOT flagged
  SELECT y.case_barcode
  FROM young_female_brca AS y
  LEFT JOIN flagged AS f
  ON y.case_barcode = f.case_barcode
  WHERE f.case_barcode IS NULL
),
eligible_files AS (     -- map to file UUIDs in r14 metadata
  SELECT DISTINCT
    SUBSTR(f.file_name,1,12) AS case_barcode,
    f.file_gdc_id
  FROM `isb-cgc.GDC_metadata.rel14_fileData_current` AS f
  WHERE SUBSTR(f.file_name,1,12) IN (SELECT case_barcode FROM eligible_cases)
)
SELECT
  e.case_barcode,
  g.file_gdc_url
FROM eligible_cases  AS e
JOIN eligible_files  AS f  ON e.case_barcode = f.case_barcode
JOIN `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` AS g
     ON f.file_gdc_id = g.file_gdc_id
ORDER BY e.case_barcode;