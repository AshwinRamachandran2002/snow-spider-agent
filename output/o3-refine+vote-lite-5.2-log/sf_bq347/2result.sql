WITH base_mr AS (   -- all instances belonging to the specified MR series
    SELECT 
        "SOPInstanceUID",
        "Modality"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
seg_uid_list AS (   -- segmentation SOPInstanceUIDs that reference the MR series
    SELECT DISTINCT "segmentationInstanceUID" AS "SOPInstanceUID"
    FROM IDC.IDC_V17.QUANTITATIVE_MEASUREMENTS
    WHERE "sourceSegmentedSeriesUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
    
    UNION
    
    SELECT DISTINCT "segmentationInstanceUID"
    FROM IDC.IDC_V17.QUALITATIVE_MEASUREMENTS
    WHERE "sourceSegmentedSeriesUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
    
    UNION
    
    SELECT DISTINCT "SOPInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS
    WHERE "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
seg_instances AS (  -- modalities of those segmentation SOPs
    SELECT 
        d."SOPInstanceUID",
        d."Modality"
    FROM IDC.IDC_V17.DICOM_ALL d
    JOIN seg_uid_list s
      ON d."SOPInstanceUID" = s."SOPInstanceUID"
),
all_instances AS (  -- union of MR and associated SEG instances
    SELECT * FROM base_mr
    UNION ALL
    SELECT * FROM seg_instances
)
SELECT 
    "Modality",
    COUNT(*) AS "Total_SOPInstances"
FROM all_instances
GROUP BY "Modality"
ORDER BY "Total_SOPInstances" DESC NULLS LAST
LIMIT 1;