/*--------------------------------------------------------------
  Female (gender = 'FEMALE') TCGA-BRCA patients aged ≤ 30 years
  with NO disqualifying annotations
        ───────────────────────────────────────────────────────
  1)  annot_exclude   – barcodes to discard
  2)  candidate_cases – young female BRCA barcodes
  3)  eligible_cases  – keep only candidates not excluded
  4)  release14_files – all files in rel-14, with barcode parsed
  5)  FINAL SELECT    – distinct barcode + GDC file URL
----------------------------------------------------------------*/
WITH annot_exclude AS (               -- 1
  SELECT DISTINCT case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE LOWER(entity_type) = 'patient'
    AND (category = 'History of unacceptable prior treatment related to a prior/other malignancy'
         OR classification = 'Redaction')
),
candidate_cases AS (                 -- 2
  SELECT DISTINCT case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE disease_code = 'BRCA'
    AND UPPER(gender) = 'FEMALE'
    AND age_at_diagnosis <= 30        -- years
),
eligible_cases AS (                  -- 3
  SELECT c.case_barcode
  FROM candidate_cases AS c
  LEFT JOIN annot_exclude USING (case_barcode)
  WHERE annot_exclude.case_barcode IS NULL
),
release14_files AS (                 -- 4
  SELECT
    f.file_gdc_id,
    SUBSTR(f.file_name, 1, 12) AS case_barcode    -- TCGA barcode
  FROM `isb-cgc.GDC_metadata.rel14_fileData_current` AS f
)
SELECT DISTINCT                       -- 5
  e.case_barcode,
  g.file_gdc_url
FROM eligible_cases                                   AS e
JOIN release14_files                                  AS f  ON e.case_barcode = f.case_barcode
JOIN `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` AS g
     ON g.file_gdc_id = f.file_gdc_id
ORDER BY e.case_barcode;