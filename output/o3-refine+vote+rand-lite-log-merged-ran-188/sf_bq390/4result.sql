WITH t2_studies AS (
    SELECT DISTINCT "StudyInstanceUID"
    FROM   IDC.IDC_V17."DICOM_PIVOT"
    WHERE  "collection_id"     = 'qin_prostate_repeatability'
      AND  "Modality"          = 'MR'
      AND  "SeriesDescription" ILIKE '%t2%'
      AND  "SeriesDescription" ILIKE '%ax%'            -- axial T2-weighted
),
seg_studies AS (
    SELECT DISTINCT p."StudyInstanceUID"
    FROM   IDC.IDC_V17."SEGMENTATIONS"  s
    JOIN   IDC.IDC_V17."DICOM_PIVOT"    p
           ON p."SeriesInstanceUID" = s."SeriesInstanceUID"
    WHERE  p."collection_id" = 'qin_prostate_repeatability'
      AND  s."SegmentedPropertyType" ILIKE '%peripheral%zone%'   -- peripheral-zone segmentations
)
SELECT DISTINCT t2."StudyInstanceUID"
FROM   t2_studies  t2
JOIN   seg_studies seg
       ON seg."StudyInstanceUID" = t2."StudyInstanceUID"
ORDER BY t2."StudyInstanceUID";