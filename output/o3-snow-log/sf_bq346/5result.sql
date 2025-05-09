WITH seg_pub AS (
  SELECT
    seg."SegmentedPropertyCategory":"CodeMeaning"::string AS category
  FROM IDC.IDC_V17.SEGMENTATIONS seg
  JOIN IDC.IDC_V17.DICOM_ALL d
        ON seg."SOPInstanceUID" = d."SOPInstanceUID"
  WHERE d."Modality"    = 'SEG'
    AND d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
    AND d."access"      = 'Public'
)
SELECT
  category AS "SegmentedPropertyCategory_CodeMeaning",
  COUNT(*)  AS "SegmentationInstances"
FROM seg_pub
WHERE category IS NOT NULL
GROUP BY category
ORDER BY "SegmentationInstances" DESC NULLS LAST
LIMIT 5;