WITH union_data AS (
    /* Original MR series instances */
    SELECT
        "Modality",
        "SOPInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'

    UNION ALL

    /* Segmentation objects that reference the MR series above */
    SELECT
        d."Modality",
        d."SOPInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS  s
    JOIN IDC.IDC_V17.DICOM_ALL      d
      ON d."SOPInstanceUID" = s."SOPInstanceUID"
    WHERE s."segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
)

SELECT
    "Modality",
    COUNT(DISTINCT "SOPInstanceUID") AS "NumSOPInstances"
FROM union_data
GROUP BY "Modality"
ORDER BY "NumSOPInstances" DESC NULLS LAST, "Modality"
LIMIT 1;