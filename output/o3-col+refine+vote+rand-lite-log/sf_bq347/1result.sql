WITH mr_series AS (                                               -- 1) the MR series itself
    SELECT 
        "Modality",
        "SOPInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
seg_series AS (                                                   -- 2) all SEG instances that reference that MR series
    SELECT  
        da."Modality",
        da."SOPInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL        da
    JOIN IDC.IDC_V17.SEGMENTATIONS    s
          ON da."SOPInstanceUID" = s."SOPInstanceUID"
    WHERE s."segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
combined AS (                                                     -- 3) union the two sets
    SELECT * FROM mr_series
    UNION ALL
    SELECT * FROM seg_series
)
SELECT                                                             -- 4) count SOP instances by modality
    "Modality",
    COUNT(*) AS "n_SOP_instances"
FROM combined
GROUP BY "Modality"
ORDER BY "n_SOP_instances" DESC NULLS LAST;