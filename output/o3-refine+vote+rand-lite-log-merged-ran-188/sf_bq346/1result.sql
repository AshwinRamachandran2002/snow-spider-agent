WITH seg AS (
    SELECT
        TO_VARCHAR(s."SegmentedPropertyCategory":"CodeMeaning") AS category
    FROM IDC.IDC_V17.SEGMENTATIONS s
    JOIN IDC.IDC_V17.DICOM_ALL d
      ON d."SOPInstanceUID" = s."SOPInstanceUID"
    WHERE d."Modality"    = 'SEG'
      AND d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
      AND d."access"      = 'Public'
      AND s."SegmentedPropertyCategory" IS NOT NULL
)
SELECT
    category AS "SegmentedPropertyCategory_CodeMeaning",
    COUNT(*) AS "SegmentationCount"
FROM seg
WHERE category IS NOT NULL
GROUP BY category
ORDER BY "SegmentationCount" DESC NULLS LAST,
         category
LIMIT 5;