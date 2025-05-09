WITH base AS (   -- all CT instances from the NLST collection
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        TRY_TO_DOUBLE("SpacingBetweenSlices")                      AS slice_interval,
        COALESCE("ExposureInmAs", TRY_TO_DOUBLE("Exposure"))       AS exposure_value,
        "instance_size"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality" = 'CT'
),
series_metrics AS (           -- one row per series
    SELECT
        "PatientID"                          AS patient_id,
        "SeriesInstanceUID"                  AS series_uid,
        AVG(slice_interval)                  AS slice_interval_series,
        AVG(exposure_value)                  AS exposure_series,
        SUM("instance_size")/1048576.0       AS series_size_mib        -- bytes ➔ MiB
    FROM base
    GROUP BY patient_id, series_uid
),
patient_metrics AS (          -- one row per patient
    SELECT
        patient_id,
        MAX(slice_interval_series) - MIN(slice_interval_series)  AS slice_interval_range,
        MAX(exposure_series)        - MIN(exposure_series)       AS exposure_range,
        AVG(series_size_mib)                                   AS avg_series_size_mib
    FROM series_metrics
    GROUP BY patient_id
),
-- top-3 patients by slice-interval tolerance
top_slice AS (
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY slice_interval_range DESC NULLS LAST) AS rn
    FROM patient_metrics
    WHERE slice_interval_range IS NOT NULL
),
-- top-3 patients by exposure difference
top_exposure AS (
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY exposure_range DESC NULLS LAST) AS rn
    FROM patient_metrics
    WHERE exposure_range IS NOT NULL
),
result_slice AS (
    SELECT
        'Top 3 by Slice Interval'                        AS group_label,
        AVG(avg_series_size_mib)                         AS average_series_size_mib
    FROM top_slice
    WHERE rn <= 3
),
result_exposure AS (
    SELECT
        'Top 3 by Max Exposure'                          AS group_label,
        AVG(avg_series_size_mib)                         AS average_series_size_mib
    FROM top_exposure
    WHERE rn <= 3
)
-- final two-row result set
SELECT
    group_label,
    ROUND(average_series_size_mib, 4) AS average_series_size_mib
FROM (
    SELECT * FROM result_slice
    UNION ALL
    SELECT * FROM result_exposure
);