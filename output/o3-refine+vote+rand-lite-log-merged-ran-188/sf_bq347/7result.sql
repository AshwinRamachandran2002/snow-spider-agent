WITH
-- UID of the MR series of interest
target_mr_series AS (
    SELECT '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147' AS "SeriesInstanceUID"
),

-- All segmentation series that reference the target MR series
segmentation_series AS (
    SELECT DISTINCT "SeriesInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS
    WHERE "segmented_SeriesInstanceUID" = (SELECT "SeriesInstanceUID" FROM target_mr_series)
),

-- Union of SOP instances from the target MR series and all associated segmentation series
union_instances AS (
    SELECT "Modality", "SOPInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" = (SELECT "SeriesInstanceUID" FROM target_mr_series)
    
    UNION ALL
    
    SELECT "Modality", "SOPInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" IN (SELECT "SeriesInstanceUID" FROM segmentation_series)
)

-- Count SOP instances per modality and select the modality with the greatest count
SELECT
    "Modality",
    COUNT(DISTINCT "SOPInstanceUID") AS "Total_SOP_Instances"
FROM union_instances
GROUP BY "Modality"
ORDER BY "Total_SOP_Instances" DESC NULLS LAST
LIMIT 1;