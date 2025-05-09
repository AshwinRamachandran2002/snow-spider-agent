/*  Distinct studies in the “qin_prostate_repeatability” collection that
    (1) contain at least one segmentation labelled “Peripheral zone”, and
    (2) include at least one MR series whose description implies T2-weighted axial imaging.
*/
WITH
-- studies that have a “Peripheral zone” segmentation --------------------------
seg_studies AS (
    SELECT DISTINCT da."StudyInstanceUID"
    FROM  IDC.IDC_V17."DICOM_ALL"        da
    JOIN  IDC.IDC_V17."SEGMENTATIONS"    seg
          ON seg."SeriesInstanceUID" = da."SeriesInstanceUID"
    WHERE da."collection_id" = 'qin_prostate_repeatability'
      AND seg."SegmentedPropertyType" ILIKE '%Peripheral zone%'
),

-- studies that have a T2-weighted axial MR series -----------------------------
t2_studies AS (
    SELECT DISTINCT "StudyInstanceUID"
    FROM  IDC.IDC_V17."DICOM_ALL"
    WHERE "collection_id" = 'qin_prostate_repeatability'
      AND "Modality" = 'MR'
      AND UPPER("SeriesDescription") LIKE '%T2%'
      AND ( UPPER("SeriesDescription") LIKE '%AX%'      -- “AX”, “AXIAL”, etc.
         OR UPPER("SeriesDescription") LIKE '%AXIAL%' )
)

-- intersection of the two criteria -------------------------------------------
SELECT DISTINCT seg."StudyInstanceUID"
FROM   seg_studies seg
JOIN   t2_studies  t2
  ON   seg."StudyInstanceUID" = t2."StudyInstanceUID";