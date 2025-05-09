WITH per_series AS (   -- series–level metrics
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        AVG(TRY_TO_DOUBLE("SliceThickness"))                             AS slice_interval,
        AVG(TRY_TO_DOUBLE("Exposure"))                                   AS exposure_value,
        SUM("instance_size")/1048576.0                                   AS series_size_mib
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality" = 'CT'
      AND "instance_size" IS NOT NULL
    GROUP BY
        "PatientID",
        "SeriesInstanceUID"
), patient_metrics AS (  -- patient–level metrics
    SELECT
        "PatientID",
        MAX(slice_interval) - MIN(slice_interval)        AS slice_interval_tolerance,
        MAX(exposure_value)  - MIN(exposure_value)       AS exposure_difference,
        AVG(series_size_mib)                            AS avg_series_size_mib
    FROM per_series
    GROUP BY "PatientID"
), top_slice_patients AS (   -- top‑3 by slice‑interval tolerance
    SELECT *
    FROM patient_metrics
    ORDER BY slice_interval_tolerance DESC NULLS LAST
    LIMIT 3
), top_exposure_patients AS ( -- top‑3 by exposure difference
    SELECT *
    FROM patient_metrics
    ORDER BY exposure_difference DESC NULLS LAST
    LIMIT 3
)
-- final result
SELECT 'Top 3 by Slice Interval' AS "GroupLabel",
       AVG(avg_series_size_mib)  AS "AverageSeriesSizeMiB"
FROM top_slice_patients

UNION ALL

SELECT 'Top 3 by Max Exposure'   AS "GroupLabel",
       AVG(avg_series_size_mib)  AS "AverageSeriesSizeMiB"
FROM top_exposure_patients;