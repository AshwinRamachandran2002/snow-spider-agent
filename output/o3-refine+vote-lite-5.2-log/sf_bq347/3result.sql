WITH
-- all SOP instances in the specified MR series
mr_instances AS (
    SELECT
        "Modality",
        "SOPInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

-- segmentation series that reference the specified MR series
seg_series AS (
    SELECT DISTINCT
        "SeriesInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS
    WHERE "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

-- all SOP instances belonging to those segmentation series
seg_instances AS (
    SELECT
        d."Modality",
        d."SOPInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL d
    JOIN seg_series s
      ON d."SeriesInstanceUID" = s."SeriesInstanceUID"
)

-- union MR and segmentation instances, count by modality, and pick the largest
SELECT
    "Modality",
    COUNT(*) AS "sop_instance_count"
FROM (
    SELECT * FROM mr_instances
    UNION ALL
    SELECT * FROM seg_instances
) AS all_relevant_instances
GROUP BY "Modality"
ORDER BY "sop_instance_count" DESC NULLS LAST
LIMIT 1;