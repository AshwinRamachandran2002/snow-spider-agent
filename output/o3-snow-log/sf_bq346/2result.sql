SELECT
    category,
    COUNT(*) AS occurrences
FROM (
    SELECT
        seg."SegmentedPropertyCategory":"CodeMeaning"::STRING AS category
    FROM IDC.IDC_V17."SEGMENTATIONS" AS seg
    JOIN IDC.IDC_V17."DICOM_ALL"     AS dcm
      ON seg."SOPInstanceUID" = dcm."SOPInstanceUID"
    WHERE dcm."Modality"    = 'SEG'
      AND dcm."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
      AND dcm."access"      = 'Public'
      AND seg."SegmentedPropertyCategory" IS NOT NULL
) AS derived
GROUP BY category
ORDER BY occurrences DESC NULLS LAST
LIMIT 5;