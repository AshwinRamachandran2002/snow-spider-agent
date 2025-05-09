SELECT s."SegmentedPropertyCategory":"CodeMeaning"::STRING AS "SegmentedPropertyCategory.CodeMeaning",
       COUNT(*) AS "OccurrenceCount"
FROM IDC.IDC_V17."SEGMENTATIONS" s
JOIN IDC.IDC_V17."DICOM_PIVOT" d
  ON s."SOPInstanceUID" = d."SOPInstanceUID"
WHERE d."Modality" = 'SEG'
  AND d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
GROUP BY s."SegmentedPropertyCategory":"CodeMeaning"::STRING
ORDER BY "OccurrenceCount" DESC NULLS LAST
LIMIT 5;