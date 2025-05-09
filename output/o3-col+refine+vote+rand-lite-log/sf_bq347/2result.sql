WITH
-- SOPs belonging to the requested MR series
mr_sops AS (
    SELECT DISTINCT "SOPInstanceUID"
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
-- SOPs of segmentation objects that reference the MR series
seg_sops AS (
    -- SEG objects recorded in QUANTITATIVE_MEASUREMENTS
    SELECT DISTINCT "segmentationInstanceUID" AS "SOPInstanceUID"
    FROM   IDC.IDC_V17.QUANTITATIVE_MEASUREMENTS
    WHERE  "sourceSegmentedSeriesUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
    UNION
    -- SEG objects listed in the SEGMENTATIONS table
    SELECT DISTINCT "SOPInstanceUID"
    FROM   IDC.IDC_V17.SEGMENTATIONS
    WHERE  "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
-- Union of all SOPs (MR + associated segmentations)
all_relevant_sops AS (
    SELECT * FROM mr_sops
    UNION
    SELECT * FROM seg_sops
)
-- Count SOP instances per modality and return the modality with the highest count
SELECT   d."Modality",
         COUNT(DISTINCT d."SOPInstanceUID") AS "total_sop_instances"
FROM     IDC.IDC_V17.DICOM_ALL d
JOIN     all_relevant_sops r
       ON d."SOPInstanceUID" = r."SOPInstanceUID"
GROUP BY d."Modality"
ORDER BY "total_sop_instances" DESC NULLS LAST
LIMIT 1;