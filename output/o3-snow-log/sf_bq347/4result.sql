WITH mr AS (
    SELECT "SOPInstanceUID",
           "Modality"
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
seg AS (
    SELECT da."SOPInstanceUID",
           da."Modality"
    FROM   IDC.IDC_V17.MEASUREMENT_GROUPS mg
           JOIN IDC.IDC_V17.DICOM_ALL da
             ON da."SOPInstanceUID" = mg."segmentationInstanceUID"
    WHERE  mg."sourceSegmentedSeriesUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
)
SELECT   "Modality",
         COUNT(*) AS "NumInstances"
FROM    (SELECT * FROM mr
         UNION ALL
         SELECT * FROM seg)
GROUP BY "Modality"
ORDER BY "NumInstances" DESC NULLS LAST
LIMIT 1;