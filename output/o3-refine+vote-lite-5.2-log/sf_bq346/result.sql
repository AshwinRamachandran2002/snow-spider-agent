SELECT
  seg."SegmentedPropertyCategory":"CodeMeaning"::string                    AS "SegmentedPropertyCategory_CodeMeaning",
  COUNT(*)                                                                 AS "SegmentationCount"
FROM IDC.IDC_V17."SEGMENTATIONS"      seg
JOIN IDC.IDC_V17."DICOM_ALL"          d
  ON seg."SOPInstanceUID" = d."SOPInstanceUID"
WHERE d."Modality"   = 'SEG'
  AND d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
GROUP BY seg."SegmentedPropertyCategory":"CodeMeaning"::string
ORDER BY "SegmentationCount" DESC NULLS LAST
LIMIT 5;