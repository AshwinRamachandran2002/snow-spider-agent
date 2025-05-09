/*  Female BRCA patients (age ≤ 30) without disqualifying annotations –
    list every associated file’s GCS URL (GDC release 14)              */

WITH bad_history AS (          -- 1. barcodes with “bad-history” / Redaction
  SELECT DISTINCT case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE entity_type = 'Patient'
    AND (category = 'History of unacceptable prior treatment related to a prior/other malignancy'
         OR classification = 'Redaction')
),
young_female_brca AS (         -- 2. female, BRCA, ≤30 yrs
  SELECT DISTINCT case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE UPPER(gender) = 'FEMALE'
    AND disease_code         = 'BRCA'
    AND age_at_diagnosis    <= 30
),
eligible_cases AS (            -- 3. keep barcodes NOT in bad_history
  SELECT y.case_barcode
  FROM young_female_brca y
  LEFT JOIN bad_history b USING (case_barcode)
  WHERE b.case_barcode IS NULL        -- ⇒ categoryName & classificationName both NULL
),
case2uuid AS (                 -- 4. map barcode → case UUID (rel14_caseData)
  SELECT e.case_barcode,
         d.case_gdc_id
  FROM eligible_cases                          e
  JOIN `isb-cgc.GDC_metadata.rel14_caseData` d
    ON e.case_barcode = d.case_barcode
),
files AS (                     -- 5. all current files for each eligible case UUID
  SELECT c.case_barcode,
         f.file_gdc_id
  FROM case2uuid                                 c
  JOIN `isb-cgc.GDC_metadata.rel14_fileData_current` f
    ON c.case_gdc_id = f.associated_entities__case_gdc_id
)
-- 6. attach GCS URL and output distinct pairs
SELECT DISTINCT
  fi.case_barcode,
  u.file_gdc_url
FROM files                                            fi
JOIN `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` u
  ON fi.file_gdc_id = u.file_gdc_id
ORDER BY fi.case_barcode;