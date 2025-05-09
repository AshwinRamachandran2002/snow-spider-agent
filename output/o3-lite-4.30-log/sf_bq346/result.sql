SELECT
    s."SegmentedPropertyCategory":"CodeMeaning"::STRING AS segmented_property_category,
    COUNT(*)                                           AS segment_count
FROM IDC.IDC_V17."SEGMENTATIONS"  AS s
JOIN IDC.IDC_V17."DICOM_ALL"      AS d
  ON s."SOPInstanceUID" = d."SOPInstanceUID"
WHERE d."access"         = 'Public'
  AND d."Modality"       = 'SEG'
  AND d."SOPClassUID"    = '1.2.840.10008.5.1.4.1.1.66.4'
  AND d."SourceImageSequence" IS NOT NULL      -- ensure the SEG references source images
  AND s."SegmentedPropertyCategory" IS NOT NULL
GROUP BY segmented_property_category
ORDER BY segment_count DESC NULLS LAST, segmented_property_category
LIMIT 5;