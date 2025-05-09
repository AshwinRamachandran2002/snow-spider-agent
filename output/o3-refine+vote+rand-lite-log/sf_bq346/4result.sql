SELECT 
    code_meaning                                               AS "SegmentedPropertyCategory_CodeMeaning",
    COUNT(*)                                                   AS "SegmentationsCount"
FROM (
    SELECT
        s."SegmentedPropertyCategory":"CodeMeaning"::STRING    AS code_meaning
    FROM IDC.IDC_V17."SEGMENTATIONS"       AS s
    JOIN IDC.IDC_V17."DICOM_ALL"           AS d
      ON d."SOPInstanceUID" = s."SOPInstanceUID"
    WHERE d."Modality"    = 'SEG'
      AND d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
      AND d."access"      = 'Public'
      AND s."SegmentedPropertyCategory":"CodeMeaning" IS NOT NULL
)
GROUP BY code_meaning
ORDER BY "SegmentationsCount" DESC NULLS LAST, "SegmentedPropertyCategory_CodeMeaning"
LIMIT 5;