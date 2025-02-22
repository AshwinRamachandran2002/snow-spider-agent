-- Task: List up to 100 SOPInstanceUIDs, along with their SegmentedPropertyType CodeMeaning and SegmentedPropertyCategory CodeMeaning, from DICOM_ALL joined with SEGMENTATIONS.
SELECT
  "dicom_all_seg"."SOPInstanceUID",
  "segmentations"."SegmentedPropertyType":"CodeMeaning" AS "segPropertyTypeCodeMeaning",
  "segmentations"."SegmentedPropertyCategory":"CodeMeaning" AS "segPropertyCategoryCodeMeaning"
FROM
  "IDC"."IDC_V17"."DICOM_ALL" AS "dicom_all_seg"
JOIN
  "IDC"."IDC_V17"."SEGMENTATIONS" AS "segmentations"
ON
  "dicom_all_seg"."SOPInstanceUID" = "segmentations"."SOPInstanceUID"
LIMIT 100;