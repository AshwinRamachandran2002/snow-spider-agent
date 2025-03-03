SELECT DISTINCT c.case_barcode, gp.file_gdc_url
FROM `isb-cgc.TCGA_bioclin_v0.Clinical` AS c
JOIN `isb-cgc.TCGA_bioclin_v0.Annotations` AS a
  ON c.case_barcode = a.case_barcode
JOIN `isb-cgc.GDC_metadata.rel14_fileData_current` AS fd
  ON fd.case_gdc_id = c.case_gdc_id
JOIN `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` AS gp
  ON fd.file_gdc_id = gp.file_gdc_id
WHERE c.gender = 'FEMALE'
  AND c.age_at_diagnosis IS NOT NULL
  AND c.age_at_diagnosis <= 30 * 365
  AND c.disease_code = 'BRCA'
  AND (LOWER(a.classification) = 'redaction' OR LOWER(a.category) LIKE '%prior malignancy%')