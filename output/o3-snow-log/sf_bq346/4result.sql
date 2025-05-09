SELECT
    code_meaning                         AS "SegmentedPropertyCategory_CodeMeaning",
    COUNT(*)                             AS "Segmentation_Count"
FROM (
    /*  all SEG modality instances for the SEG SOP Class  */
    SELECT
        TO_VARCHAR(s."SegmentedPropertyCategory":"CodeMeaning")  AS code_meaning
    FROM  IDC.IDC_V17.SEGMENTATIONS      AS s
    JOIN  IDC.IDC_V17.DICOM_ALL          AS d
          ON s."SOPInstanceUID" = d."SOPInstanceUID"
    WHERE d."Modality"   = 'SEG'
      AND d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
) t
WHERE code_meaning IS NOT NULL
GROUP BY code_meaning
ORDER BY "Segmentation_Count" DESC NULLS LAST
LIMIT 5;