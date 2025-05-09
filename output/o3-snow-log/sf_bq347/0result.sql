WITH
-- SOPs from the specified MR series
base_series AS (
    SELECT "SOPInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
-- SOPs of segmentation objects that reference that MR series
segmentation_series AS (
    SELECT "SOPInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS
    WHERE "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
-- union of MR plus associated SEG instances
union_instances AS (
    SELECT "SOPInstanceUID" FROM base_series
    UNION ALL
    SELECT "SOPInstanceUID" FROM segmentation_series
)
-- count SOPs per modality and pick the largest
SELECT
    d."Modality",
    COUNT(*) AS "num_instances"
FROM union_instances u
JOIN IDC.IDC_V17.DICOM_ALL d
      ON d."SOPInstanceUID" = u."SOPInstanceUID"
GROUP BY d."Modality"
ORDER BY "num_instances" DESC NULLS LAST
LIMIT 1;