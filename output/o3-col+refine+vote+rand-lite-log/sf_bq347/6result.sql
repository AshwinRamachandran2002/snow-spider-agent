WITH seg_series AS (
    /* all segmentation series that reference the specified MR series */
    SELECT DISTINCT "SeriesInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS
    WHERE "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
union_set AS (
    /* every SOP instance that belongs either to the MR series itself or to any of its segmentation series */
    SELECT "Modality"
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
       OR  "SeriesInstanceUID" IN (SELECT "SeriesInstanceUID" FROM seg_series)
)
SELECT   "Modality",
         COUNT(*) AS "sop_instances"
FROM     union_set
GROUP BY "Modality"
ORDER BY "sop_instances" DESC NULLS LAST
LIMIT 1;