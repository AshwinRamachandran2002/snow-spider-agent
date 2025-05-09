/*  Five most frequent segmentation categories (CodeMeaning) in
    publicly‑accessible SEG objects that
      • have Modality = 'SEG'
      • use the SEG Storage SOP Class UID
      • reference the source instance/series                                   */

SELECT
    s."SegmentedPropertyCategory":"CodeMeaning"::STRING   AS "Segmentation_Category",
    COUNT(*)                                              AS "Segmentation_Count"
FROM  IDC.IDC_V17.SEGMENTATIONS  AS s
JOIN  IDC.IDC_V17.DICOM_ALL      AS d
      ON s."SOPInstanceUID" = d."SOPInstanceUID"
WHERE d."Modality"        = 'SEG'
  AND d."SOPClassUID"     = '1.2.840.10008.5.1.4.1.1.66.4'
  AND d."access"          = 'Public'                       -- only publicly accessible data
  AND s."segmented_SeriesInstanceUID" IS NOT NULL          -- must reference original data
  AND s."SegmentedPropertyCategory":"CodeMeaning" IS NOT NULL
GROUP BY "Segmentation_Category"
ORDER BY "Segmentation_Count" DESC
LIMIT 5;