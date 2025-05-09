WITH
-- SOPs that belong to the requested MR series
orig AS (
    SELECT DISTINCT "SOPInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

-- segmentation SOPs recorded in SEGMENTATIONS table
seg1 AS (
    SELECT DISTINCT "SOPInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS
    WHERE "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

-- segmentation SOPs referenced in QUANTITATIVE_MEASUREMENTS table
seg2 AS (
    SELECT DISTINCT "segmentationInstanceUID"          AS "SOPInstanceUID"
    FROM IDC.IDC_V17.QUANTITATIVE_MEASUREMENTS
    WHERE "sourceSegmentedSeriesUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

-- segmentation SOPs referenced in MEASUREMENT_GROUPS table
seg3 AS (
    SELECT DISTINCT "segmentationInstanceUID"          AS "SOPInstanceUID"
    FROM IDC.IDC_V17.MEASUREMENT_GROUPS
    WHERE "sourceSegmentedSeriesUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

-- union of all relevant SOPInstanceUIDs
union_sops AS (
    SELECT * FROM orig
    UNION
    SELECT * FROM seg1
    UNION
    SELECT * FROM seg2
    UNION
    SELECT * FROM seg3
)

-- determine modality with the greatest number of instances
SELECT
    d."Modality",
    COUNT(*) AS "num_sop_instances"
FROM union_sops u
JOIN IDC.IDC_V17.DICOM_ALL d
  ON d."SOPInstanceUID" = u."SOPInstanceUID"
GROUP BY d."Modality"
ORDER BY "num_sop_instances" DESC NULLS LAST
LIMIT 1;