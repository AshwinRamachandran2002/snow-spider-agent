/* ---------------------------------------------------------------------------
   TCGA‑BRCA female patients ≤ 30 yrs old
   – drop any case that has either
       • category = "History of unacceptable prior treatment …"
       • classification = "Redaction"
   – return every GDC file‑URL from archive release 14 that belongs
     to the remaining (eligible) cases.
--------------------------------------------------------------------------- */

WITH flagged AS (            -- cases that must be excluded
  SELECT DISTINCT case_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Annotations`
  WHERE entity_type = 'Patient'
    AND (
          category = 'History of unacceptable prior treatment related to a prior/other malignancy'
          OR classification = 'Redaction'
        )
),

young_brca AS (              -- female BRCA patients ≤ 30 yrs
  SELECT DISTINCT
         case_barcode,
         case_gdc_id
  FROM `isb-cgc.TCGA_bioclin_v0.Clinical`
  WHERE UPPER(disease_code) = 'BRCA'
    AND UPPER(gender)       = 'FEMALE'
    AND age_at_diagnosis IS NOT NULL
    AND age_at_diagnosis    <= 30
),

eligible_cases AS (          -- keep only un‑flagged cases
  SELECT y.case_barcode,
         y.case_gdc_id
  FROM young_brca AS y
  LEFT JOIN flagged AS f
    ON y.case_barcode = f.case_barcode
  WHERE f.case_barcode IS NULL
),

cases_r14 AS (               -- ensure the case exists in release 14 metadata
  SELECT DISTINCT
         ec.case_barcode,
         ec.case_gdc_id
  FROM eligible_cases  AS ec
  JOIN `isb-cgc.GDC_metadata.rel14_caseData` cd
    ON cd.case_gdc_id = ec.case_gdc_id
)

-- Final output: every file URL (release 14) for each eligible case
SELECT DISTINCT
       cr14.case_barcode,
       gcs.file_gdc_url AS gdc_file_url
FROM cases_r14 AS cr14
JOIN `isb-cgc.GDC_metadata.rel14_fileData_current` fd
  ON fd.case_gdc_id = cr14.case_gdc_id               -- link files → case
JOIN `isb-cgc.GDC_metadata.rel14_GDCfileID_to_GCSurl_NEW` gcs
  ON gcs.file_gdc_id = fd.file_id                    -- UUID → GCS URL
ORDER BY
       cr14.case_barcode,
       gdc_file_url;