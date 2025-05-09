WITH base AS (
    /* NLST CT instances with numeric slice‑interval and exposure values */
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        TRY_CAST("SpacingBetweenSlices" AS FLOAT) AS spacing_val,
        TRY_CAST("Exposure"            AS FLOAT) AS exposure_val,
        "instance_size"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality"      = 'CT'
),
/* Per–patient slice‑interval and exposure spans */
patient_metrics AS (
    SELECT
        "PatientID",
        MAX(spacing_val)  - MIN(spacing_val)  AS diff_spacing,
        MAX(exposure_val) - MIN(exposure_val) AS diff_exposure
    FROM base
    GROUP BY "PatientID"
),
/* Top‑3 patients by each metric */
top_slice_patients AS (
    SELECT "PatientID"
    FROM   patient_metrics
    ORDER  BY diff_spacing DESC NULLS LAST, "PatientID"
    LIMIT  3
),
top_exposure_patients AS (
    SELECT "PatientID"
    FROM   patient_metrics
    ORDER  BY diff_exposure DESC NULLS LAST, "PatientID"
    LIMIT  3
),
/* Series sizes in MiB */
series_sizes AS (
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        SUM("instance_size") / 1048576.0 AS series_size_mib
    FROM base
    GROUP BY "PatientID", "SeriesInstanceUID"
),
/* Average series size for each group */
avg_slice AS (
    SELECT ROUND(AVG(series_size_mib),4) AS avg_series_size_mib
    FROM   series_sizes
    WHERE  "PatientID" IN (SELECT "PatientID" FROM top_slice_patients)
),
avg_exposure AS (
    SELECT ROUND(AVG(series_size_mib),4) AS avg_series_size_mib
    FROM   series_sizes
    WHERE  "PatientID" IN (SELECT "PatientID" FROM top_exposure_patients)
)
/* Final result */
SELECT 'Top 3 by Slice Interval' AS group_label,
       (SELECT avg_series_size_mib FROM avg_slice)    AS average_series_size_mib
UNION ALL
SELECT 'Top 3 by Max Exposure'   AS group_label,
       (SELECT avg_series_size_mib FROM avg_exposure) AS average_series_size_mib;