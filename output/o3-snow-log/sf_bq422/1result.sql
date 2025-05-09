WITH ct_series AS (   --  series–level data for NLST CT images
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        /* slice interval & exposure as numeric values (may be NULL) */
        CAST(NULLIF("SpacingBetweenSlices",'') AS FLOAT)     AS slice_interval,
        CAST(NULLIF("Exposure",'')                AS FLOAT)  AS exposure_value,
        /* series size converted from bytes to MiB */
        SUM("instance_size")/(1024*1024.0)                  AS series_size_mib
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality"      = 'CT'
    GROUP BY
        "PatientID",
        "SeriesInstanceUID",
        "SpacingBetweenSlices",
        "Exposure"
),
patient_metrics AS (   --  patient-level metrics
    SELECT
        "PatientID",
        AVG(series_size_mib)                               AS patient_avg_series_size_mib,
        /* difference between max & min unique slice intervals / exposures */
        MAX(slice_interval)  - MIN(slice_interval)         AS slice_interval_diff,
        MAX(exposure_value) - MIN(exposure_value)          AS exposure_diff,
        COUNT(DISTINCT slice_interval)                     AS n_slice_vals,
        COUNT(DISTINCT exposure_value)                     AS n_exposure_vals
    FROM ct_series
    GROUP BY "PatientID"
),
top_slice AS (   --  top-3 patients by slice–interval tolerance
    SELECT patient_avg_series_size_mib
    FROM   patient_metrics
    WHERE  n_slice_vals     >= 2          -- need at least two distinct intervals
      AND  slice_interval_diff IS NOT NULL
    ORDER BY slice_interval_diff DESC NULLS LAST
    LIMIT 3
),
top_exposure AS (   --  top-3 patients by exposure tolerance
    SELECT patient_avg_series_size_mib
    FROM   patient_metrics
    WHERE  n_exposure_vals  >= 2          -- need at least two distinct exposures
      AND  exposure_diff IS NOT NULL
    ORDER BY exposure_diff DESC NULLS LAST
    LIMIT 3
)
SELECT 'Top 3 by Slice Interval' AS "Group",
       ROUND(AVG(patient_avg_series_size_mib),4) AS "Average Series Size (MiB)"
FROM   top_slice

UNION ALL

SELECT 'Top 3 by Max Exposure'  AS "Group",
       ROUND(AVG(patient_avg_series_size_mib),4) AS "Average Series Size (MiB)"
FROM   top_exposure;