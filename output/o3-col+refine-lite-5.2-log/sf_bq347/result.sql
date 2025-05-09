WITH
-- SOP instances belonging to the requested MR series
mr_series AS (
    SELECT 
        "Modality",
        "SOPInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

-- Segmentation SOP instances that reference the same MR series
seg_series AS (
    SELECT 
        d."Modality",
        d."SOPInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL           d
    JOIN IDC.IDC_V17.SEGMENTATIONS       s
      ON d."SOPInstanceUID" = s."SOPInstanceUID"
    WHERE s."segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

-- Union of MR and associated segmentation instances
combined AS (
    SELECT * FROM mr_series
    UNION ALL
    SELECT * FROM seg_series
)

-- Count SOP instances per modality and keep the one with the highest count
SELECT 
    "Modality",
    COUNT(DISTINCT "SOPInstanceUID") AS "total_instances"
FROM combined
GROUP BY "Modality"
ORDER BY "total_instances" DESC, "Modality" ASC
LIMIT 1;