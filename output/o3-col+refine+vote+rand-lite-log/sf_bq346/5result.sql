SELECT
    s."SegmentedPropertyCategory":"CodeMeaning"::STRING  AS "Category_Name",
    COUNT(*)                                            AS "Segmentation_Count"
FROM  IDC.IDC_V17.SEGMENTATIONS   s
JOIN  IDC.IDC_V17.DICOM_ALL       d
      ON d."SOPInstanceUID" = s."SOPInstanceUID"
WHERE d."Modality"     = 'SEG'
  AND d."SOPClassUID"  = '1.2.840.10008.5.1.4.1.1.66.4'
  AND d."access"       = 'Public'                       -- publicly-accessible data
  AND s."segmented_SeriesInstanceUID" IS NOT NULL       -- segmentation references original images
GROUP BY "Category_Name"
ORDER BY "Segmentation_Count" DESC NULLS LAST
LIMIT 5;