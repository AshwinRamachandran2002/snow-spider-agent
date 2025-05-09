SELECT 
    category,
    COUNT(*) AS occurrences
FROM (
    SELECT
        SEG."SegmentedPropertyCategory":"CodeMeaning"::STRING AS category
    FROM IDC.IDC_V17."SEGMENTATIONS"  SEG
    JOIN IDC.IDC_V17."DICOM_ALL"      D
      ON SEG."SOPInstanceUID" = D."SOPInstanceUID"
    WHERE D."access"      = 'Public'
      AND D."Modality"    = 'SEG'
      AND D."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
) AS filtered
GROUP BY category
ORDER BY occurrences DESC NULLS LAST
LIMIT 5;