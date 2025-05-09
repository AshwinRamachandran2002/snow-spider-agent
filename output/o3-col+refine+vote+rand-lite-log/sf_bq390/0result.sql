SELECT DISTINCT
       d."StudyInstanceUID"
FROM   IDC.IDC_V17."DICOM_PIVOT"      d
JOIN   IDC.IDC_V17."SEGMENTATIONS"    s
       ON s."segmented_SeriesInstanceUID" = d."SeriesInstanceUID"
WHERE  d."collection_id"   = 'qin_prostate_repeatability'
  AND  d."Modality"        = 'MR'
  AND  d."SeriesDescription" ILIKE '%T2%'      -- T2-weighted
  AND  d."SeriesDescription" ILIKE '%AX%'      -- axial
  AND  s."SegmentedPropertyType" ILIKE '%Peripheral%zone%';