/*  TCGA: female BRCA patients ≤30 y without disqualifying annotations – release 14 file URLs  */
WITH flagged AS (       -- patients to exclude
  SELECT DISTINCT case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE entity_type = 'Patient'
    AND (category = 'History of unacceptable prior treatment related to a prior/other malignancy'
         OR classification = 'Redaction')
),
young_female_brca AS (  -- initial clinical cohort
  SELECT
    case_barcode,
    case_gdc_id
  FROM `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE disease_code = 'BRCA'
    AND gender        = 'FEMALE'
    AND age_at_diagnosis <= 30
),
eligible_cases AS (     -- remove flagged patients
  SELECT y.case_barcode,
         y.case_gdc_id
  FROM   young_female_brca AS y
  LEFT JOIN flagged       AS f
    ON  y.case_barcode = f.case_barcode
  WHERE f.case_barcode IS NULL          -- keep only un‑flagged
)
SELECT DISTINCT
  ec.case_barcode,
  url.file_gdc_url AS gdc_file_url
FROM  eligible_cases AS ec
JOIN  `isb-cgc.GDC_metadata.rel14_fileData_current` AS fd
      ON fd.associated_entities__case_gdc_id = ec.case_gdc_id
JOIN  `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` AS url
      ON url.file_gdc_id = fd.file_id
ORDER BY ec.case_barcode,
         gdc_file_url;