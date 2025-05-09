SELECT
  s."SegmentedPropertyCategory":"CodeMeaning"::STRING AS segmented_property_category,
  COUNT(*)                                           AS segment_count
FROM IDC.IDC_V17.SEGMENTATIONS s
JOIN IDC.IDC_V17.DICOM_ALL      d
     ON s."SOPInstanceUID" = d."SOPInstanceUID"
WHERE d."Modality"                 = 'SEG'
  AND d."SOPClassUID"              = '1.2.840.10008.5.1.4.1.1.66.4'
  AND s."segmented_SeriesInstanceUID" IS NOT NULL
GROUP BY 1
ORDER BY segment_count DESC NULLS LAST,
         segmented_property_category
LIMIT 5;