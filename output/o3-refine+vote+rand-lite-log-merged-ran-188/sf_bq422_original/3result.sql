WITH ct_nlst AS (   --  All NLST CT instances
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        "instance_size",
        TRY_TO_DOUBLE(NULLIF("SpacingBetweenSlices", '')) AS spacing,
        TRY_TO_DOUBLE(NULLIF("SliceThickness",        '')) AS thickness,
        TRY_TO_DOUBLE(NULLIF("Exposure",              '')) AS exposure
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality"      = 'CT'
),

-- Aggregate to the series level
series AS (
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        SUM("instance_size")                                                   AS series_bytes,
        /* slice interval for the series = first non‑NULL spacing, else thickness */
        COALESCE(
            MAX(CASE WHEN spacing  IS NOT NULL THEN spacing  END),
            MAX(CASE WHEN thickness IS NOT NULL THEN thickness END)
        )                                                                      AS slice_interval,
        /* exposure for the series */
        MAX(CASE WHEN exposure IS NOT NULL THEN exposure END)                  AS exposure
    FROM ct_nlst
    GROUP BY "PatientID", "SeriesInstanceUID"
),

-- Patient–level extrema and differences
patient_diff AS (
    SELECT
        "PatientID",
        MAX(slice_interval)                     AS max_interval,
        MIN(slice_interval)                     AS min_interval,
        MAX(exposure)                           AS max_exposure,
        MIN(exposure)                           AS min_exposure,
        (MAX(slice_interval) - MIN(slice_interval)) AS interval_diff,
        (MAX(exposure)       - MIN(exposure)  ) AS exposure_diff
    FROM series
    WHERE slice_interval IS NOT NULL            -- need an interval to rank
    GROUP BY "PatientID"
),

-- Top‑3 patients by slice‑interval tolerance
top_slice_patients AS (
    SELECT "PatientID"
    FROM patient_diff
    ORDER BY interval_diff DESC NULLS LAST
    LIMIT 3
),

-- Top‑3 patients by exposure tolerance
top_exposure_patients AS (
    SELECT "PatientID"
    FROM patient_diff
    ORDER BY exposure_diff DESC NULLS LAST
    LIMIT 3
),

-- Series for those patients
slice_series AS (
    SELECT *
    FROM series
    WHERE "PatientID" IN (SELECT "PatientID" FROM top_slice_patients)
),
exposure_series AS (
    SELECT *
    FROM series
    WHERE "PatientID" IN (SELECT "PatientID" FROM top_exposure_patients)
),

-- Average series size (MiB) for each group
slice_metric AS (
    SELECT AVG(series_bytes)/(1024*1024) AS avg_series_mib
    FROM slice_series
),
exposure_metric AS (
    SELECT AVG(series_bytes)/(1024*1024) AS avg_series_mib
    FROM exposure_series
)

-- Final output
SELECT 'Top 3 by Slice Interval' AS "Group", avg_series_mib
FROM slice_metric
UNION ALL
SELECT 'Top 3 by Max Exposure'  AS "Group", avg_series_mib
FROM exposure_metric;