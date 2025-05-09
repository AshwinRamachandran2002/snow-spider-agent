/*  Five most frequent segmentation categories (by SegmentedPropertyCategory.CodeMeaning)
    among public SEG objects whose SOPClassUID = 1.2.840.10008.5.1.4.1.1.66.4            */

SELECT
    s."SegmentedPropertyCategory":"CodeMeaning"::STRING  AS "SegmentedPropertyCategory_CodeMeaning",
    COUNT(*)                                            AS "SegmentationCount"
FROM   IDC.IDC_V17."DICOM_ALL"        d
JOIN   IDC.IDC_V17."SEGMENTATIONS"    s
       ON d."SOPInstanceUID" = s."SOPInstanceUID"
WHERE  d."Modality"    = 'SEG'
  AND  d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
  AND  s."SegmentedPropertyCategory" IS NOT NULL
GROUP  BY 1
ORDER  BY "SegmentationCount" DESC NULLS LAST
LIMIT  5;