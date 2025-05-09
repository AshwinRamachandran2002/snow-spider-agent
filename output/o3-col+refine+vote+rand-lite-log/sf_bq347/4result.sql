WITH segmentation_series AS (
    -- all segmentation series referencing the given MR series
    SELECT DISTINCT "SeriesInstanceUID"
    FROM IDC.IDC_V17."SEGMENTATIONS"
    WHERE "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
all_related_series AS (
    -- union the original MR series with its linked segmentation series
    SELECT '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147' AS "SeriesInstanceUID"
    UNION
    SELECT "SeriesInstanceUID" FROM segmentation_series
)
SELECT
    d."Modality",
    COUNT(*) AS sop_count
FROM IDC.IDC_V17."DICOM_ALL" d
JOIN all_related_series ars
  ON d."SeriesInstanceUID" = ars."SeriesInstanceUID"
GROUP BY d."Modality"
ORDER BY sop_count DESC NULLS LAST
LIMIT 1;