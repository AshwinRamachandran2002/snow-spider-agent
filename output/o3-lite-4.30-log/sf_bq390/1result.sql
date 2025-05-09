SELECT DISTINCT
       d."StudyInstanceUID"
FROM   IDC.IDC_V17.DICOM_ALL AS d
JOIN   IDC.IDC_V17.SEGMENTATIONS AS s
       ON d."StudyInstanceUID" = s."StudyInstanceUID"
WHERE  d."collection_name" ILIKE '%qin%prostate%repeatability%'
  AND  d."Modality" = 'MR'
  AND  d."SeriesDescription" ILIKE '%T2%'
  AND (d."SeriesDescription" ILIKE '%AX%' OR d."SeriesDescription" ILIKE '%Axial%')
  AND  s."SegmentedPropertyType":"CodeMeaning"::STRING ILIKE '%Peripheral%zone%'
ORDER BY d."StudyInstanceUID";