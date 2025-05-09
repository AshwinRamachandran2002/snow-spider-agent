/*  Average series size (MiB) for two patient groups in NLST CT collection  */

WITH ct AS (   -- series‑level data
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        SUM("instance_size")                                       AS series_size_bytes,
        MIN(TRY_TO_NUMBER("SpacingBetweenSlices"))                 AS slice_interval,
        MIN("ExposureInmAs")                                       AS exposure
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality" = 'CT'
    GROUP BY "PatientID", "SeriesInstanceUID"
),

/*  Slice‑interval variability per patient  */
slice_diff AS (
    SELECT
        "PatientID",
        MAX(slice_interval) - MIN(slice_interval)                  AS slice_interval_diff
    FROM ct
    WHERE slice_interval IS NOT NULL
    GROUP BY "PatientID"
),

/*  Exposure variability per patient  */
exp_diff AS (
    SELECT
        "PatientID",
        MAX(exposure) - MIN(exposure)                              AS exposure_diff
    FROM ct
    WHERE exposure IS NOT NULL
    GROUP BY "PatientID"
),

/*  Top‑3 patients by each metric  */
slice_top AS (
    SELECT "PatientID"
    FROM slice_diff
    ORDER BY slice_interval_diff DESC NULLS LAST, "PatientID"
    LIMIT 3
),
exp_top AS (
    SELECT "PatientID"
    FROM exp_diff
    ORDER BY exposure_diff DESC NULLS LAST, "PatientID"
    LIMIT 3
),

/*  Average series size (MiB) within each group  */
slice_result AS (
    SELECT
        'Top 3 by Slice Interval'                                   AS group_label,
        AVG(series_size_bytes) / 1048576                           AS avg_series_size_mib
    FROM ct
    WHERE "PatientID" IN (SELECT "PatientID" FROM slice_top)
),
exp_result AS (
    SELECT
        'Top 3 by Max Exposure'                                     AS group_label,
        AVG(series_size_bytes) / 1048576                           AS avg_series_size_mib
    FROM ct
    WHERE "PatientID" IN (SELECT "PatientID" FROM exp_top)
)

/*  Final output  */
SELECT * FROM slice_result
UNION ALL
SELECT * FROM exp_result;