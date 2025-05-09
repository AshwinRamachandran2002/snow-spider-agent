-- Breast-cancer (BRCA) females ≤30 yr old, un-flagged in Annotations,
-- and the GDC URLs of all their files (release-14)

WITH annot AS (         -- 1. flagged patients in Annotations
  SELECT DISTINCT
    case_barcode,
    category        AS categoryName,
    classification  AS classificationName
  FROM `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE entity_type = 'Patient'
    AND ( category = 'History of unacceptable prior treatment related to a prior/other malignancy'
          OR classification = 'Redaction' )
),

clin AS (          -- 2. target clinical cohort
  SELECT DISTINCT
    case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE disease_code = 'BRCA'
    AND UPPER(gender) = 'FEMALE'
    AND age_at_diagnosis IS NOT NULL
    AND age_at_diagnosis <= 30
),

merged AS (        -- 3. FULL JOIN, keep rows where *both* annotation fields are NULL
  SELECT
    COALESCE(c.case_barcode, a.case_barcode) AS case_barcode,
    a.categoryName,
    a.classificationName
  FROM clin AS c
  FULL JOIN annot AS a
  ON c.case_barcode = a.case_barcode
),

eligible_cases AS (
  SELECT case_barcode
  FROM merged
  WHERE categoryName IS NULL           -- retain only un-flagged cases
    AND classificationName IS NULL
),

file_ids AS (      -- 4. files whose name starts with the case barcode (release-14 current)
  SELECT DISTINCT
    e.case_barcode,
    f.file_gdc_id
  FROM eligible_cases            AS e
  JOIN `isb-cgc.GDC_metadata.rel14_fileData_current` AS f
    ON LOWER(f.file_name) LIKE CONCAT(LOWER(e.case_barcode), '%')
)

-- 5. map file UUIDs to their GCS URLs
SELECT DISTINCT
  fi.case_barcode,
  g.file_gdc_url
FROM file_ids AS fi
JOIN `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` AS g
  ON g.file_gdc_id = fi.file_gdc_id
ORDER BY fi.case_barcode;