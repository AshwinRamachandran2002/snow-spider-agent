SELECT 
  category AS "SegmentedPropertyCategory_CodeMeaning",
  COUNT(*) AS "Occurrences"
FROM (
  SELECT 
    /* extract the CodeMeaning from the JSON object */
    (SEG."SegmentedPropertyCategory":"CodeMeaning")::STRING AS category
  FROM IDC.IDC_V17."SEGMENTATIONS"            SEG
  JOIN IDC.IDC_V17."DICOM_ALL"                DA
        ON SEG."SOPInstanceUID" = DA."SOPInstanceUID"
  WHERE DA."Modality"   = 'SEG'
    AND DA."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
    AND DA."access"      = 'Public'           -- keep only publicly‑accessible data
) AS sub
WHERE category IS NOT NULL
GROUP BY category
ORDER BY "Occurrences" DESC NULLS LAST, category
LIMIT 5;