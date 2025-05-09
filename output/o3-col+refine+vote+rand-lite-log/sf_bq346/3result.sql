SELECT
  s."SegmentedPropertyCategory":"CodeMeaning"::STRING AS "Category_CodeMeaning",
  COUNT(*)                                           AS "segment_count"
FROM IDC.IDC_V17."SEGMENTATIONS"          AS s
JOIN IDC.IDC_V17."DICOM_ALL"              AS d
  ON d."SOPInstanceUID" = s."SOPInstanceUID"
WHERE d."Modality"    = 'SEG'
  AND d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
  AND s."segmented_SeriesInstanceUID" IS NOT NULL        -- ensure it references original images
GROUP BY "Category_CodeMeaning"
ORDER BY "segment_count" DESC NULLS LAST
LIMIT 5;