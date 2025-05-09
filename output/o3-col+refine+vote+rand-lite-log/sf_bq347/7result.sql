WITH mr_sops AS (
    -- SOP instances from the target MR series
    SELECT 
        "SOPInstanceUID",
        "Modality"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
seg_sops AS (
    -- SOP instances from segmentation series that reference the target MR series
    SELECT 
        d."SOPInstanceUID",
        d."Modality"
    FROM IDC.IDC_V17.SEGMENTATIONS s
    JOIN IDC.IDC_V17.DICOM_ALL d
          ON d."SeriesInstanceUID" = s."SeriesInstanceUID"
    WHERE s."segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
)
SELECT 
    "Modality",
    COUNT(*) AS "Total_SOPs"
FROM (
    SELECT * FROM mr_sops
    UNION ALL
    SELECT * FROM seg_sops
) all_sops
GROUP BY "Modality"
ORDER BY "Total_SOPs" DESC NULLS LAST
LIMIT 1;