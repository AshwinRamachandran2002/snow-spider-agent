SELECT
    s."SegmentedPropertyCategory":"CodeMeaning"::string        AS "SegmentedPropertyCategory_CodeMeaning",
    COUNT(*)                                                  AS "Segmentation_Count"
FROM
    IDC.IDC_V17."SEGMENTATIONS"          AS s
JOIN
    IDC.IDC_V17."DICOM_ALL"              AS d
      ON s."SOPInstanceUID" = d."SOPInstanceUID"
WHERE
      d."Modality"    = 'SEG'
  AND d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
  AND d."access"      = 'Public'
GROUP BY
    "SegmentedPropertyCategory_CodeMeaning"
ORDER BY
    "Segmentation_Count" DESC NULLS LAST,
    "SegmentedPropertyCategory_CodeMeaning"
LIMIT 5;