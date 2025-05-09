WITH main_instances AS (
    /* SOP Instances from the specified MR series */
    SELECT 
        "SOPInstanceUID",
        "Modality"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
    
    UNION ALL
    
    /* SOP Instances from all segmentation series that reference the specified MR series */
    SELECT 
        da."SOPInstanceUID",
        da."Modality"
    FROM IDC.IDC_V17.DICOM_ALL  da
    JOIN (
        SELECT DISTINCT "SeriesInstanceUID"
        FROM IDC.IDC_V17.SEGMENTATIONS
        WHERE "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
    ) seg
      ON da."SeriesInstanceUID" = seg."SeriesInstanceUID"
)

SELECT 
    "Modality",
    COUNT(*) AS "SOPInstances"
FROM main_instances
GROUP BY "Modality"
ORDER BY "SOPInstances" DESC NULLS LAST
LIMIT 1;