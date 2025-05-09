WITH series_of_interest AS (          -- given MR series
    SELECT '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147' AS series_uid
),
segmentation_series AS (              -- segmentation series linked to that MR series
    SELECT DISTINCT "SeriesInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS, series_of_interest
    WHERE "segmented_SeriesInstanceUID" = series_uid
),
all_series AS (                       -- union of the MR series and all associated segmentation series
    SELECT series_uid AS "SeriesInstanceUID" FROM series_of_interest
    UNION ALL
    SELECT "SeriesInstanceUID"        -- segmentation series
    FROM segmentation_series
),
instances AS (                        -- all SOP instances belonging to those series
    SELECT DA."Modality",
           DA."SOPInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL AS DA
    JOIN all_series AS S
      ON DA."SeriesInstanceUID" = S."SeriesInstanceUID"
)
SELECT   "Modality",
         COUNT(DISTINCT "SOPInstanceUID") AS "Total_SOP_Instances"
FROM     instances
GROUP BY "Modality"
ORDER BY "Total_SOP_Instances" DESC NULLS LAST
LIMIT 1;