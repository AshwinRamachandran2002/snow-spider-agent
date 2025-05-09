SELECT
  CONCAT(
    seg."SegmentedPropertyCategory":"CodeMeaning"::STRING,
    ' (',
    seg."SegmentedPropertyCategory":"CodeValue"::STRING,
    ')'
  ) AS "SegmentationCategory",
  COUNT(*) AS "Count"
FROM "IDC"."IDC_V17"."DICOM_PIVOT" dp
JOIN "IDC"."IDC_V17"."SEGMENTATIONS" seg
  ON dp."SOPInstanceUID" = seg."SOPInstanceUID"
WHERE dp."Modality" = 'SEG'
  AND dp."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
GROUP BY "SegmentationCategory"
ORDER BY "Count" DESC NULLS LAST
LIMIT 5;