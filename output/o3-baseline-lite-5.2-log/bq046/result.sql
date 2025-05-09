/*--------------------------------------------------------------------
   TCGA‑BRCA   |   females ≤ 30 yrs   |   no disqualifying annotation
--------------------------------------------------------------------*/
WITH annotation_cases AS (        -- patients to exclude
  SELECT
    LOWER(case_barcode)                      AS case_barcode_lc,
    MAX(category)        AS categoryName,
    MAX(classification)  AS classificationName
  FROM `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE LOWER(entity_type) = 'patient'
    AND (
         category       = 'History of unacceptable prior treatment related to a prior/other malignancy'
         OR classification = 'Redaction'
        )
  GROUP BY case_barcode_lc
),

clinical_cases AS (               -- BRCA, female, ≤ 30 yrs
  SELECT
    case_barcode,
    case_gdc_id
  FROM `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE disease_code       = 'BRCA'
    AND UPPER(gender)      = 'FEMALE'
    AND age_at_diagnosis  IS NOT NULL
    AND age_at_diagnosis  <= 30
),

combined AS (                     -- FULL JOIN and keep rows w/ no bad annotation
  SELECT
    COALESCE(c.case_barcode, UPPER(a.case_barcode_lc)) AS case_barcode,
    c.case_gdc_id,
    a.categoryName,
    a.classificationName
  FROM clinical_cases  AS c
  FULL JOIN annotation_cases AS a
    ON LOWER(c.case_barcode) = a.case_barcode_lc
),

filtered_cases AS (               -- retain only acceptable cases
  SELECT
    case_barcode,
    case_gdc_id
  FROM combined
  WHERE categoryName       IS NULL
    AND classificationName IS NULL
),

files_for_cases AS (              -- release‑14 file UUIDs for those cases
  SELECT DISTINCT
    fc.case_barcode,
    f.file_id AS file_gdc_id
  FROM filtered_cases AS fc
  JOIN `isb-cgc.GDC_metadata.rel14_fileData_current` AS f
    ON f.case_gdc_id = fc.case_gdc_id
)

-- Map UUIDs → GCS URLs (release‑14) and reference rel14_caseData per task
SELECT
  ff.case_barcode,
  g.file_gdc_url AS gdc_file_url
FROM files_for_cases AS ff
JOIN `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` AS g
  ON g.file_gdc_id = ff.file_gdc_id
CROSS JOIN (SELECT 1 FROM `isb-cgc.GDC_metadata.rel14_caseData` LIMIT 1) AS _
ORDER BY
  ff.case_barcode;