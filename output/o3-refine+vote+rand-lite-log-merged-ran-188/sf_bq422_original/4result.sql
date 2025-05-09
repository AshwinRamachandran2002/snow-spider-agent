/*---------------------------------------------------------------------------
   Average series size (MiB) for NLST CT images
   1) for the 3 patients with the largest slice‑interval range
   2) for the 3 patients with the largest exposure (mAs) range
---------------------------------------------------------------------------*/
WITH filtered AS (        -- keep only NLST CT instances
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        TRY_TO_DOUBLE("SliceThickness")          AS slice_thickness,
        "ExposureInmAs"                          AS exposure_mas,
        "instance_size"                          AS instance_bytes
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality"      = 'CT'
      AND "PatientID" IS NOT NULL
      AND "SeriesInstanceUID" IS NOT NULL
),

series_level AS (         -- series‑level slice interval, exposure and size
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        AVG(DISTINCT slice_thickness)                AS slice_interval,
        AVG(DISTINCT exposure_mas)                   AS exposure_value,
        SUM(instance_bytes)                          AS series_bytes
    FROM filtered
    GROUP BY "PatientID", "SeriesInstanceUID"
),

patient_level AS (        -- patient‑level ranges and average series size
    SELECT
        "PatientID",
        MAX(slice_interval)   - MIN(slice_interval)  AS slice_interval_diff,
        MAX(exposure_value)   - MIN(exposure_value)  AS exposure_diff,
        AVG(series_bytes) / (1024*1024)              AS avg_series_size_mib
    FROM series_level
    GROUP BY "PatientID"
),

top_slice AS (            -- top‑3 by slice‑interval tolerance
    SELECT  avg_series_size_mib
    FROM    patient_level
    WHERE   slice_interval_diff IS NOT NULL
    ORDER BY slice_interval_diff DESC NULLS LAST, "PatientID"
    LIMIT 3
),

top_exposure AS (         -- top‑3 by exposure range
    SELECT  avg_series_size_mib
    FROM    patient_level
    WHERE   exposure_diff IS NOT NULL
    ORDER BY exposure_diff DESC NULLS LAST, "PatientID"
    LIMIT 3
)

SELECT 'Top 3 by Slice Interval' AS "Group",
       ROUND(AVG(avg_series_size_mib),4)  AS "AverageSeriesSizeMiB"
FROM   top_slice

UNION ALL

SELECT 'Top 3 by Max Exposure'   AS "Group",
       ROUND(AVG(avg_series_size_mib),4)  AS "AverageSeriesSizeMiB"
FROM   top_exposure;