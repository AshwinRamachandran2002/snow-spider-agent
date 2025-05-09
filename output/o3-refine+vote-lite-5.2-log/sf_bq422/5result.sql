/*  Average series size (MiB) for NLST CT images
    1) for the 3 patients with the largest slice–interval range
    2) for the 3 patients with the largest exposure‑(mAs) range            */

WITH base AS (   -- NLST CT instances
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        TRY_TO_DOUBLE("SpacingBetweenSlices")      AS spacing_val,     -- mm
        TRY_TO_DOUBLE("ExposureInmAs")             AS exposure_mAs,    -- mAs
        "instance_size"                            AS bytes
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality"      = 'CT'
),

/* ----- series size (MiB) ------------------------------------------------ */
series_sizes AS (
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        SUM(bytes)/1048576.0                      AS series_size_mib
    FROM base
    GROUP BY "PatientID","SeriesInstanceUID"
),

/* ----- average series size per patient ---------------------------------- */
patient_avg_series_size AS (
    SELECT
        "PatientID",
        AVG(series_size_mib)                     AS avg_series_size_mib
    FROM series_sizes
    GROUP BY "PatientID"
),

/* ----- per‑patient variability metrics ---------------------------------- */
patient_metrics AS (
    SELECT
        "PatientID",
        MAX(spacing_val)  - MIN(spacing_val)     AS slice_interval_diff,   -- mm
        MAX(exposure_mAs) - MIN(exposure_mAs)    AS exposure_diff          -- mAs
    FROM base
    GROUP BY "PatientID"
),

/* ----- combine size & variability --------------------------------------- */
patient_combined AS (
    SELECT
        pm."PatientID",
        pm.slice_interval_diff,
        pm.exposure_diff,
        pas.avg_series_size_mib
    FROM patient_metrics          pm
    JOIN patient_avg_series_size  pas
      ON pm."PatientID" = pas."PatientID"
),

/* ----- top‑3 lists ------------------------------------------------------ */
top_slice AS (
    SELECT *
    FROM patient_combined
    WHERE slice_interval_diff IS NOT NULL
    ORDER BY slice_interval_diff DESC NULLS LAST
    LIMIT 3
),
top_exposure AS (
    SELECT *
    FROM patient_combined
    WHERE exposure_diff IS NOT NULL
    ORDER BY exposure_diff DESC NULLS LAST
    LIMIT 3
)

/* ----- final report ----------------------------------------------------- */
SELECT 'Top 3 by Slice Interval'  AS "Group",
       ROUND(AVG(avg_series_size_mib),4) AS "AverageSeriesSize_MiB"
FROM top_slice

UNION ALL

SELECT 'Top 3 by Max Exposure'    AS "Group",
       ROUND(AVG(avg_series_size_mib),4) AS "AverageSeriesSize_MiB"
FROM top_exposure
;