SELECT
    t."CodeMeaning" AS "SegmentedPropertyCategory_CodeMeaning",
    COUNT(*)        AS "Segmentations_Count"
FROM (
        SELECT
            seg."SegmentedPropertyCategory":"CodeMeaning"::STRING AS "CodeMeaning"
        FROM
            IDC.IDC_V17."SEGMENTATIONS"  seg
        INNER JOIN 
            IDC.IDC_V17."DICOM_ALL"      d
                ON seg."SOPInstanceUID" = d."SOPInstanceUID"
        WHERE
            d."Modality"   = 'SEG'
            AND d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
            AND d."access" = 'Public'
            AND seg."SegmentedPropertyCategory":"CodeMeaning" IS NOT NULL
     ) t
GROUP BY
    t."CodeMeaning"
ORDER BY
    "Segmentations_Count" DESC NULLS LAST
LIMIT 5;