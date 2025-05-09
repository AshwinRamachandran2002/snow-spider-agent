/* 1) Patients flagged in TCGA annotations                                */
WITH annotation_flags AS (
  SELECT DISTINCT
         case_barcode,
         case_gdc_id,
         category,
         classification
  FROM   `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE  entity_type = 'Patient'
    AND ( category = 'History of unacceptable prior treatment related to a prior/other malignancy'
          OR classification = 'Redaction' )
),

/* 2) Female BRCA patients ≤ 30 yrs old                                   */
clinical_brca_young_female AS (
  SELECT DISTINCT
         case_barcode,
         case_gdc_id
  FROM   `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE  disease_code = 'BRCA'
    AND  UPPER(gender) = 'FEMALE'
    AND  age_at_diagnosis IS NOT NULL
    AND  age_at_diagnosis <= 30
),

/* 3) Full‑join, keep only patients with NO disqualifying annotation      */
eligible_cases AS (
  SELECT DISTINCT
         COALESCE(c.case_barcode , a.case_barcode) AS case_barcode,
         COALESCE(c.case_gdc_id  , a.case_gdc_id ) AS case_gdc_id
  FROM   clinical_brca_young_female c
  FULL JOIN annotation_flags        a
         ON c.case_barcode = a.case_barcode
  WHERE  a.category IS NULL
     AND a.classification IS NULL
     AND COALESCE(c.case_barcode , a.case_barcode) IS NOT NULL
)

/* 4) Attach GDC files (release‑14 current) and corresponding GCS URLs    */
SELECT
       ec.case_barcode,
       gcs.file_gdc_url
FROM   eligible_cases                                    ec
JOIN   `isb-cgc.GDC_metadata.rel14_fileData_current`     fd
       ON fd.case_gdc_id = ec.case_gdc_id
JOIN   `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` gcs
       ON gcs.file_gdc_id = fd.file_id
ORDER  BY ec.case_barcode,
          gcs.file_gdc_url;