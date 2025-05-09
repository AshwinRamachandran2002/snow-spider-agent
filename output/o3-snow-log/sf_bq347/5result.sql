WITH
-- 1.  Series UID of segmentations that reference the given MR series
"seg_series" AS (
    SELECT DISTINCT
        "SeriesInstanceUID"
    FROM IDC.IDC_V17."SEGMENTATIONS"
    WHERE "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

-- 2.  SOP instances from the MR series plus all SOP instances belonging to the
--     associated segmentation series
"mr_and_seg_instances" AS (
    -- MR series instances
    SELECT
        "Modality",
        "SOPInstanceUID"
    FROM IDC.IDC_V17."DICOM_ALL"
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'

    UNION ALL

    -- Segmentation instances associated with that MR series
    SELECT
        "Modality",
        "SOPInstanceUID"
    FROM IDC.IDC_V17."DICOM_ALL"
    WHERE "SeriesInstanceUID" IN (SELECT "SeriesInstanceUID" FROM "seg_series")
)

-- 3.  Count SOP instances per modality and return the modality with the highest count
SELECT
    "Modality",
    COUNT(*) AS "Total_SOP_Instances"
FROM "mr_and_seg_instances"
GROUP BY "Modality"
ORDER BY "Total_SOP_Instances" DESC NULLS LAST
LIMIT 1;