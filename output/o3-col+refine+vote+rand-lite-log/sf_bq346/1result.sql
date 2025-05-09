SELECT
    cat."Segment_Category",
    COUNT(*) AS "num_segs"
FROM (
    /* pull category for every public SEG object of the specified SOP Class */
    SELECT
        s."SegmentedPropertyCategory":"CodeMeaning"::STRING AS "Segment_Category"
    FROM IDC.IDC_V17.DICOM_ALL         d
    JOIN IDC.IDC_V17.SEGMENTATIONS     s
      ON d."SOPInstanceUID" = s."SOPInstanceUID"
    WHERE d."access"      = 'Public'
      AND d."Modality"    = 'SEG'
      AND d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
      AND s."SegmentedPropertyCategory" IS NOT NULL
) AS cat
GROUP BY cat."Segment_Category"
ORDER BY "num_segs" DESC NULLS LAST
LIMIT 5;