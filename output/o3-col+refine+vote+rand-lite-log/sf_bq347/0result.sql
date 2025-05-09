WITH mr_series AS (
    SELECT "SOPInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
seg_series AS (
    SELECT "SOPInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS
    WHERE "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
all_sops AS (
    SELECT * FROM mr_series
    UNION ALL
    SELECT * FROM seg_series
)
SELECT
    d."Modality",
    COUNT(*) AS "total_instances"
FROM all_sops a
JOIN IDC.IDC_V17.DICOM_ALL d
  ON a."SOPInstanceUID" = d."SOPInstanceUID"
GROUP BY d."Modality"
ORDER BY "total_instances" DESC NULLS LAST
LIMIT 1;