WITH seg AS (
    SELECT
        s."SegmentedPropertyCategory":"CodeMeaning"::STRING  AS "Category"
    FROM
        IDC.IDC_V17."SEGMENTATIONS"                AS s
    JOIN
        IDC.IDC_V17."DICOM_ALL"                    AS d
          ON s."SOPInstanceUID" = d."SOPInstanceUID"
    WHERE
        d."Modality"        = 'SEG'
        AND d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
        AND d."access"      = 'Public'                 -- publicly-accessible data
        AND s."SegmentedPropertyCategory" IS NOT NULL  -- has category information
)
SELECT
    "Category"                                          AS "SegmentedPropertyCategory_CodeMeaning",
    COUNT(*)                                            AS "segment_count"
FROM
    seg
GROUP BY
    "Category"
ORDER BY
    "segment_count" DESC NULLS LAST
LIMIT 5;