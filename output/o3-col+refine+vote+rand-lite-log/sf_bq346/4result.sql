SELECT
    s."SegmentedPropertyCategory":"CodeMeaning"::STRING  AS "SegmentedPropertyCategory_CodeMeaning",
    COUNT(*)                                            AS "Occurrences"
FROM  "IDC"."IDC_V17"."SEGMENTATIONS"  s
JOIN  "IDC"."IDC_V17"."DICOM_ALL"      d
      ON s."SOPInstanceUID" = d."SOPInstanceUID"
WHERE d."Modality"      = 'SEG'
  AND d."SOPClassUID"   = '1.2.840.10008.5.1.4.1.1.66.4'
  AND s."segmented_SeriesInstanceUID" IS NOT NULL          -- ensure SEG references original images
GROUP BY "SegmentedPropertyCategory_CodeMeaning"
ORDER BY "Occurrences" DESC NULLS LAST
LIMIT 5;