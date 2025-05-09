WITH original_instances AS (   -- SOP instances in the specified MR series
    SELECT
        "SOPInstanceUID",
        "Modality"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
segmentation_uids AS (         -- segmentation SOPs that reference that MR series
    SELECT
        "SOPInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS
    WHERE "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
segmentation_instances AS (    -- modalities of those segmentation SOPs
    SELECT
        d."SOPInstanceUID",
        d."Modality"
    FROM IDC.IDC_V17.DICOM_ALL d
    JOIN segmentation_uids s
      ON d."SOPInstanceUID" = s."SOPInstanceUID"
),
combined AS (                  -- union of MR series and associated segmentations
    SELECT * FROM original_instances
    UNION ALL
    SELECT * FROM segmentation_instances
)
SELECT
    "Modality",
    COUNT(DISTINCT "SOPInstanceUID") AS "Total_SOP_Instances"
FROM combined
GROUP BY "Modality"
ORDER BY "Total_SOP_Instances" DESC NULLS LAST
LIMIT 1;