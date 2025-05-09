WITH seg_objects AS (
    SELECT "SOPInstanceUID"
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  "Modality"     = 'SEG'
      AND  "SOPClassUID"  = '1.2.840.10008.5.1.4.1.1.66.4'
      AND  "access"       = 'Public'          -- publicly-accessible instances
)

SELECT
       s."SegmentedPropertyCategory":"CodeMeaning"::STRING AS "Segment_Category",
       COUNT(*)                                            AS "Segment_Count"
FROM   IDC.IDC_V17.SEGMENTATIONS s
JOIN   seg_objects o
  ON   s."SOPInstanceUID" = o."SOPInstanceUID"
GROUP  BY "Segment_Category"
ORDER  BY "Segment_Count" DESC NULLS LAST
LIMIT  5;