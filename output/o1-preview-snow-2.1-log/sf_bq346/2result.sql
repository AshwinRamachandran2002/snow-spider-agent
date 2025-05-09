SELECT
    COALESCE(s."SegmentedPropertyCategory"::VARIANT:"CodeMeaning"::STRING, 'Unknown') AS "SegmentationCategory",
    COUNT(*) AS "Frequency"
FROM
    IDC.IDC_V17.SEGMENTATIONS s
JOIN
    IDC.IDC_V17.DICOM_METADATA d
    ON s."SOPInstanceUID" = d."SOPInstanceUID"
WHERE
    d."Modality" = 'SEG'
    AND d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
GROUP BY
    "SegmentationCategory"
ORDER BY
    "Frequency" DESC NULLS LAST
LIMIT 5;