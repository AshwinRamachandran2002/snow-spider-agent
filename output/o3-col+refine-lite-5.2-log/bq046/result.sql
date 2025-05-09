/*  ----------------------------------------------------------
    TCGA‑BRCA – female cases (≤ 30 yrs at diagnosis) WITHOUT
    disqualifying annotations, and one representative GCS URL
    per case (GDC Release‑14 files only)
    ---------------------------------------------------------- */
WITH annos AS (                                   -- 1) cases to EXCLUDE
    SELECT DISTINCT
           case_gdc_id,
           category        AS categoryName,
           classification  AS classificationName
    FROM   `isb-cgc.TCGA_bioclin_v0.Annotations`
    WHERE  LOWER(entity_type) = 'patient'
      AND (LOWER(category)      = 'history of unacceptable prior treatment related to a prior/other malignancy'
           OR LOWER(classification) = 'redaction')
),
young_female_brca AS (                            -- 2)  BRCA, female, ≤30 yrs
    SELECT DISTINCT
           case_barcode,
           case_gdc_id
    FROM   `isb-cgc.TCGA_bioclin_v0.Clinical`
    WHERE  disease_code       = 'BRCA'
      AND  UPPER(gender)      = 'FEMALE'
      AND  age_at_diagnosis IS NOT NULL
      AND  age_at_diagnosis   <= 30               -- age already stored in years
),
eligible_cases AS (                               -- 3)  remove disqualified
    SELECT y.*
    FROM   young_female_brca AS y
    LEFT  JOIN annos         AS a
           ON y.case_gdc_id = a.case_gdc_id
    WHERE  a.case_gdc_id IS NULL                  -- keep only “clean” cases
),
files_with_url AS (                               -- 4)  attach Release‑14 files
    SELECT
           e.case_barcode,
           g.file_gdc_url,
           ROW_NUMBER() OVER (PARTITION BY e.case_barcode
                              ORDER BY g.file_gdc_url) AS rn
    FROM   eligible_cases                                   AS e
    JOIN   `isb-cgc.GDC_metadata.rel14_fileData_current`    AS f
           ON f.associated_entities__case_gdc_id = e.case_gdc_id
    JOIN   `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` AS g
           ON g.file_gdc_id = f.file_id
)
-- 5)  final list: one (arbitrary first) URL per eligible case
SELECT
       case_barcode,
       file_gdc_url  AS example_gcs_url
FROM   files_with_url
WHERE  rn = 1
ORDER  BY case_barcode;