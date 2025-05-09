SELECT
    category,
    COUNT(*) AS segmentation_count
FROM (
    SELECT
        s."SegmentedPropertyCategory":"CodeMeaning"::STRING AS category
    FROM IDC.IDC_V17.SEGMENTATIONS              s
    JOIN IDC.IDC_V17.DICOM_ALL                  d
      ON d."SOPInstanceUID" = s."SOPInstanceUID"
    WHERE d."Modality"   = 'SEG'
      AND d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
      AND s."SegmentedPropertyCategory" IS NOT NULL
) AS derived
WHERE category IS NOT NULL
GROUP BY category
ORDER BY segmentation_count DESC NULLS LAST, category
LIMIT 5;