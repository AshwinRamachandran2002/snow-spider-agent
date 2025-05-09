/* ------------------------------------------------------------------
   TCGA‑BRCA ‑ female patients ≤30 y, NOT flagged  →  GDC file URLs
   ------------------------------------------------------------------ */
WITH flagged AS (               -- patients carrying disqualifying annotations
  SELECT DISTINCT
         entity_barcode                 AS case_barcode,
         category                        AS categoryName,
         classification                  AS classificationName
  FROM `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE entity_type = 'Patient'
    AND (category = 'History of unacceptable prior treatment related to a prior/other malignancy'
         OR classification = 'Redaction')
),
young_female_brca AS (          -- BRCA, female, ≤30 years
  SELECT DISTINCT
         case_barcode,
         case_gdc_id
  FROM `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE disease_code = 'BRCA'
    AND UPPER(gender) = 'FEMALE'
    AND age_at_diagnosis IS NOT NULL
    AND age_at_diagnosis <= 30
),
full_join AS (                  -- FULL join as requested
  SELECT
        y.case_barcode,
        y.case_gdc_id,
        f.categoryName,
        f.classificationName
  FROM young_female_brca AS y
  FULL JOIN flagged       AS f
    ON y.case_barcode = f.case_barcode
),
eligible_cases AS (             -- keep only patients with NO flag columns
  SELECT
        case_barcode,
        case_gdc_id
  FROM full_join
  WHERE categoryName IS NULL
    AND classificationName IS NULL
    AND case_barcode IS NOT NULL         -- ensures patient comes from the young‑female set
)
SELECT DISTINCT
       e.case_barcode,
       u.file_gdc_url AS gdc_file_url
FROM eligible_cases                                AS e
JOIN `isb-cgc.GDC_metadata.rel14_fileData_current` AS f
  ON f.case_gdc_id = e.case_gdc_id
JOIN `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` AS u
  ON u.file_gdc_id = f.file_id
WHERE u.file_gdc_url IS NOT NULL
ORDER BY e.case_barcode,
         u.file_gdc_url;