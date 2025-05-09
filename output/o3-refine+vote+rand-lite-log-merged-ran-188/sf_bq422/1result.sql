/*  Compute and compare the average CT-series sizes (MiB) for  
    1) the 3 NLST patients with the widest slice-interval tolerance  
    2) the 3 NLST patients with the widest exposure (mAs) range      */

WITH ct_nlst AS (   -- NLST CT slices only
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        "SpacingBetweenSlices",
        "ExposureInmAs",
        "instance_size"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality"      = 'CT'
),

/* ----------  Top-3 patients by slice-interval tolerance ---------- */
slice_tol AS (
    SELECT
        "PatientID",
        MAX(TRY_TO_NUMBER(NULLIF("SpacingBetweenSlices",''))) -
        MIN(TRY_TO_NUMBER(NULLIF("SpacingBetweenSlices",'')))      AS slice_interval_tol,
        ROW_NUMBER() OVER (ORDER BY
            MAX(TRY_TO_NUMBER(NULLIF("SpacingBetweenSlices",''))) -
            MIN(TRY_TO_NUMBER(NULLIF("SpacingBetweenSlices",'')))
            DESC NULLS LAST)                                       AS rn
    FROM ct_nlst
    WHERE  "SpacingBetweenSlices" IS NOT NULL
       AND TRIM("SpacingBetweenSlices") <> ''
       AND TRY_TO_NUMBER(NULLIF("SpacingBetweenSlices",'')) IS NOT NULL
    GROUP BY "PatientID"
    HAVING COUNT(DISTINCT TRY_TO_NUMBER(NULLIF("SpacingBetweenSlices",''))) > 1
    QUALIFY rn <= 3
),

/* ----------  Top-3 patients by exposure range -------------------- */
exposure_diff AS (
    SELECT
        "PatientID",
        MAX("ExposureInmAs") - MIN("ExposureInmAs")                AS exposure_range,
        ROW_NUMBER() OVER (ORDER BY
            MAX("ExposureInmAs") - MIN("ExposureInmAs")
            DESC NULLS LAST)                                       AS rn
    FROM ct_nlst
    WHERE "ExposureInmAs" IS NOT NULL
    GROUP BY "PatientID"
    HAVING COUNT(DISTINCT "ExposureInmAs") > 1
    QUALIFY rn <= 3
),

/* ----------  Series sizes (MiB) ---------------------------------- */
series_sizes AS (
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        SUM("instance_size")/1048576.0                             AS series_size_mib
    FROM ct_nlst
    GROUP BY "PatientID", "SeriesInstanceUID"
),

/* ----------  Average series size for each patient group ---------- */
avg_slice_group AS (
    SELECT
        'Top 3 by Slice Interval'                                   AS group_label,
        ROUND(AVG(series_size_mib),2)                               AS avg_series_size_mib
    FROM series_sizes
    WHERE "PatientID" IN (SELECT "PatientID" FROM slice_tol)
),

avg_exposure_group AS (
    SELECT
        'Top 3 by Max Exposure'                                     AS group_label,
        ROUND(AVG(series_size_mib),2)                               AS avg_series_size_mib
    FROM series_sizes
    WHERE "PatientID" IN (SELECT "PatientID" FROM exposure_diff)
)

/* ----------  Final combined result ------------------------------- */
SELECT * FROM avg_slice_group
UNION ALL
SELECT * FROM avg_exposure_group;