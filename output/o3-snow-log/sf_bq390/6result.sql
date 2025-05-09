WITH t2_studies AS (     -- studies that have axial T2-weighted MR series
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17.DICOM_PIVOT
    WHERE "collection_id" = 'qin_prostate_repeatability'
      AND "Modality" = 'MR'
      AND UPPER("SeriesDescription") LIKE '%T2%'
      AND (UPPER("SeriesDescription") LIKE '%AXIAL%' 
           OR UPPER("SeriesDescription") LIKE '% AX %' 
           OR UPPER("SeriesDescription") LIKE '%AX_%')
), 
seg_pz_studies AS (      -- studies that include Peripheral zone segmentations
    SELECT DISTINCT p."StudyInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS        s
    JOIN IDC.IDC_V17.DICOM_PIVOT          p
         ON p."SeriesInstanceUID" = s."SeriesInstanceUID"
    WHERE p."collection_id" = 'qin_prostate_repeatability'
      AND s."SegmentedPropertyType":"CodeMeaning"::STRING ILIKE '%PERIPHERAL%ZONE%'
)
SELECT DISTINCT t."StudyInstanceUID"
FROM t2_studies     t
JOIN seg_pz_studies s
  ON s."StudyInstanceUID" = t."StudyInstanceUID"
ORDER BY t."StudyInstanceUID";