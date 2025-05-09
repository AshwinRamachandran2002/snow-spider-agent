/*---------------------------------------------------------------------------
  Female TCGA‑BRCA patients (≤ 30 yrs) **without** disqualifying annotations
  and the URLs of their GDC files – using release 14 metadata tables
---------------------------------------------------------------------------*/
WITH annotation_patients AS (        -- 1. patients to EXCLUDE
  SELECT DISTINCT
         case_barcode,
         case_gdc_id,
         category        AS categoryName,
         classification  AS classificationName
  FROM   `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE  entity_type = 'Patient'
    AND ( category = 'History of unacceptable prior treatment related to a prior/other malignancy'
           OR classification = 'Redaction' )
),

clinical_patients AS (               -- 2. female BRCA ≤ 30 yrs
  SELECT DISTINCT
         case_barcode,
         case_gdc_id
  FROM   `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE  disease_code = 'BRCA'
    AND  UPPER(gender) = 'FEMALE'
    AND  age_at_diagnosis IS NOT NULL
    AND  age_at_diagnosis <= 30
),

combined AS (                        -- 3. full join to retain annotation cols
  SELECT
         COALESCE(c.case_barcode, a.case_barcode) AS case_barcode,
         COALESCE(c.case_gdc_id, a.case_gdc_id)   AS case_gdc_id,
         a.categoryName,
         a.classificationName
  FROM   clinical_patients  c
  FULL JOIN annotation_patients a
         ON c.case_barcode = a.case_barcode
),

eligible_cases AS (                  -- 4. keep only NON‑annotated cases
  SELECT case_barcode, case_gdc_id
  FROM   combined
  WHERE  categoryName IS NULL
     AND classificationName IS NULL
),

case_files AS (                      -- 5. release‑14 files for these cases
  SELECT DISTINCT
         ec.case_barcode,
         f.file_id AS file_gdc_id
  FROM   eligible_cases                   ec
  JOIN   `isb-cgc.GDC_metadata.rel14_fileData_current` f
         ON f.case_gdc_id = ec.case_gdc_id            -- link via UUID
)

SELECT                                   -- 6. attach GCS URLs
       cf.case_barcode,
       g.file_gdc_url AS gdc_file_url
FROM   case_files cf
JOIN   `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` g
       ON g.file_gdc_id = cf.file_gdc_id
ORDER BY
       case_barcode;