SELECT 
  seg."SegmentedPropertyType":"CodeMeaning"::STRING AS "SegmentationCategory",
  COUNT(*) AS "Count"
FROM 
  "IDC"."IDC_V17"."SEGMENTATIONS" AS seg
JOIN 
  "IDC"."IDC_V17"."DICOM_ALL" AS dicom
  ON seg."SOPInstanceUID" = dicom."SOPInstanceUID"
WHERE 
  dicom."Modality" = 'SEG' 
  AND dicom."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
  AND LOWER(dicom."access") = 'public'
  AND seg."SegmentedPropertyType":"CodeMeaning" IS NOT NULL
GROUP BY 
  seg."SegmentedPropertyType":"CodeMeaning"::STRING
ORDER BY 
  "Count" DESC NULLS LAST
LIMIT 5;