/* ----------------------------------------------------------------------------
   1)  Disqualifying annotations  (Patient-level redactions / prior-treatment)
---------------------------------------------------------------------------- */
WITH annot_bad AS (
  SELECT DISTINCT case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE entity_type = 'Patient'
    AND ( category       = 'History of unacceptable prior treatment related to a prior/other malignancy'
       OR classification = 'Redaction' )
),

/* ----------------------------------------------------------------------------
   2)  Young (≤30 yr) female BRCA cases from the clinical table
---------------------------------------------------------------------------- */
clin_young_brca AS (
  SELECT DISTINCT case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE disease_code      = 'BRCA'
    AND gender            = 'FEMALE'
    AND age_at_diagnosis <= 30
),

/* ----------------------------------------------------------------------------
   3)  FULL JOIN both sets and keep only those **without** bad annotations
---------------------------------------------------------------------------- */
eligible AS (
  SELECT y.case_barcode
  FROM clin_young_brca  AS y
  FULL JOIN annot_bad   AS a
  USING (case_barcode)
  WHERE a.case_barcode IS NULL                         -- no disqualifying note
),

/* ----------------------------------------------------------------------------
   4)  Keep only cases that actually exist in release-14 case table
---------------------------------------------------------------------------- */
eligible_r14 AS (
  SELECT e.case_barcode
  FROM eligible                       AS e
  JOIN `isb-cgc.GDC_metadata.rel14_caseData` AS c
    ON e.case_barcode = c.case_barcode
),

/* ----------------------------------------------------------------------------
   5)  Map each case to its file UUID(s) in release-14 current file table
       (filename always starts with the case barcode)
---------------------------------------------------------------------------- */
file_ids AS (
  SELECT
    er.case_barcode,
    f.file_gdc_id
  FROM eligible_r14                              AS er
  JOIN `isb-cgc.GDC_metadata.rel14_fileData_current` AS f
    ON STARTS_WITH(f.file_name, er.case_barcode)   -- filename prefix match
),

/* ----------------------------------------------------------------------------
   6)  Convert file UUIDs to GCS URLs (release-14 URL mapping table)
---------------------------------------------------------------------------- */
urls AS (
  SELECT
    fi.case_barcode,
    g.file_gdc_url
  FROM file_ids                                        AS fi
  JOIN `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` AS g
    ON fi.file_gdc_id = g.file_gdc_id
)

/* ----------------------------------------------------------------------------
   7)  Final result: distinct case barcodes and their file URLs
---------------------------------------------------------------------------- */
SELECT DISTINCT
  case_barcode,
  file_gdc_url
FROM urls
ORDER BY case_barcode;