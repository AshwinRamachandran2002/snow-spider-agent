SELECT
  category AS "SegmentedPropertyCategory.CodeMeaning",
  COUNT(*) AS "num_seg_instances"
FROM (
  SELECT
    s."SegmentedPropertyCategory":"CodeMeaning"::STRING AS category
  FROM IDC.IDC_V17."SEGMENTATIONS" s
  JOIN IDC.IDC_V17."DICOM_ALL" d
    ON d."SOPInstanceUID" = s."SOPInstanceUID"
  WHERE d."Modality" = 'SEG'
    AND d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
    AND s."segmented_SeriesInstanceUID" IS NOT NULL
) sub
GROUP BY category
ORDER BY "num_seg_instances" DESC NULLS LAST
LIMIT 5;