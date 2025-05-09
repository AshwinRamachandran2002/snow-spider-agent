WITH SegmentationSeries AS (
    SELECT DISTINCT "SeriesInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS
    WHERE "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
CombinedSOPInstances AS (
    SELECT "SOPInstanceUID", "Modality"
    FROM IDC.IDC_V17.DICOM_PIVOT
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
    UNION ALL
    SELECT "SOPInstanceUID", "Modality"
    FROM IDC.IDC_V17.DICOM_PIVOT
    WHERE "SeriesInstanceUID" IN (SELECT "SeriesInstanceUID" FROM SegmentationSeries)
)
SELECT "Modality", COUNT(*) AS "SOPInstanceCount"
FROM CombinedSOPInstances
GROUP BY "Modality"
ORDER BY "SOPInstanceCount" DESC NULLS LAST
LIMIT 1;