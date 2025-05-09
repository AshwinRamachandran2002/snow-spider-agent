WITH seg AS (
    SELECT
        s."SegmentedPropertyCategory":"CodeMeaning"::string AS segmented_property_category
    FROM IDC.IDC_V17."SEGMENTATIONS" s
    JOIN IDC.IDC_V17."DICOM_ALL"     d
      ON d."SOPInstanceUID" = s."SOPInstanceUID"
    WHERE d."Modality"    = 'SEG'
      AND d."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
      AND s."SegmentedPropertyCategory" IS NOT NULL
)
SELECT
    segmented_property_category AS "SegmentedPropertyCategory_CodeMeaning",
    COUNT(*)                    AS "segment_count"
FROM seg
GROUP BY segmented_property_category
ORDER BY "segment_count" DESC NULLS LAST,
         "SegmentedPropertyCategory_CodeMeaning"
LIMIT 5;