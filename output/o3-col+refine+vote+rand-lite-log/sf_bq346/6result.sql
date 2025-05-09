/* Five most frequent segmentation categories (SegmentedPropertyCategory.CodeMeaning)
   among publicly-accessible SEG objects (Modality='SEG', correct SOP Class UID)          */
SELECT
    s."SegmentedPropertyCategory":"CodeMeaning"::STRING AS "SegmentedPropertyCategory_CodeMeaning",
    COUNT(*)                                           AS "segment_count"
FROM IDC.IDC_V17."SEGMENTATIONS"  s
JOIN IDC.IDC_V17."DICOM_ALL"      d
      ON d."SOPInstanceUID" = s."SOPInstanceUID"
WHERE d."access"      = 'Public'                                   -- public data only
  AND d."Modality"    = 'SEG'                                      -- segmentation objects
  AND d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'             -- SEG SOP Class UID
GROUP BY 1
ORDER BY "segment_count" DESC NULLS LAST
LIMIT 5;