WITH
/* all SOP instances belonging to the specified MR series */
mr_instances AS (
    SELECT
        "SOPInstanceUID",
        "Modality"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
/* all segmentation series that reference that MR series */
seg_series AS (
    SELECT DISTINCT
        "SeriesInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS
    WHERE "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
/* SOP instances inside the associated segmentation series */
seg_instances AS (
    SELECT
        "SOPInstanceUID",
        "Modality"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" IN (SELECT "SeriesInstanceUID" FROM seg_series)
),
/* union of MR and associated segmentation instances */
combined AS (
    SELECT * FROM mr_instances
    UNION ALL
    SELECT * FROM seg_instances
)
/* determine the modality with the greatest SOP-instance count */
SELECT
    "Modality",
    COUNT(DISTINCT "SOPInstanceUID") AS sop_instance_count
FROM combined
GROUP BY "Modality"
ORDER BY sop_instance_count DESC NULLS LAST
LIMIT 1;