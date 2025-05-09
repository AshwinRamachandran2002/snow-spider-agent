WITH segs AS (
    SELECT
        s."SegmentedPropertyCategory"                                                  AS category,
        d."SOPInstanceUID"
    FROM IDC.IDC_V17."SEGMENTATIONS"             AS s
    JOIN IDC.IDC_V17."DICOM_ALL"                 AS d
          ON d."SOPInstanceUID" = s."SOPInstanceUID"
    WHERE d."Modality"      = 'SEG'
      AND d."SOPClassUID"   = '1.2.840.10008.5.1.4.1.1.66.4'
      AND d."access"        = 'Public'
)
SELECT
    category:"CodeMeaning"::STRING        AS "SegmentedPropertyCategory_CodeMeaning",
    COUNT(*)                              AS "Segmentation_Count"
FROM segs
WHERE category:"CodeMeaning" IS NOT NULL
GROUP BY 1
ORDER BY "Segmentation_Count" DESC NULLS LAST,
         "SegmentedPropertyCategory_CodeMeaning" ASC
LIMIT 5;