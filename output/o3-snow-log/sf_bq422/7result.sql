/* ------------------------------------------------------------
   Average series–size comparison for NLST CT images
   ------------------------------------------------------------
   1. cte_series
        • 1 row per Patient–Series with
          – slice interval               : numeric SpacingBetweenSlices
          – exposure value               : numeric Exposure
          – series size (bytes)          : Σ instance_size
   2. cte_patient_slice / cte_patient_exposure
        • 1 row per Patient with
          – average series size (MiB)
          – slice-interval or exposure range (max-min)
   3. Select the 3 patients with largest range for each metric.
   4. Compute the mean of their average series sizes.
---------------------------------------------------------------- */
WITH cte_series AS (
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        /* convert first component of SpacingBetweenSlices & Exposure to FLOAT */
        MIN( TRY_TO_DOUBLE( SPLIT_PART( "SpacingBetweenSlices", '\\', 1) ) )   AS slice_interval,
        MIN( TRY_TO_DOUBLE( SPLIT_PART( "Exposure",              '\\', 1) ) )   AS exposure_value,
        SUM( "instance_size" )                                                  AS series_size_bytes
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  "collection_name" = 'NLST'
      AND  "Modality"        = 'CT'
    GROUP  BY "PatientID", "SeriesInstanceUID"
),

/* ---------- slice-interval range per patient ----------------- */
cte_patient_slice AS (
    SELECT
        "PatientID",
        /* average series size per patient in MiB */
        AVG( series_size_bytes ) / (1024*1024.0)                     AS avg_series_size_mib,
        MAX( slice_interval ) - MIN( slice_interval )                AS slice_interval_diff
    FROM  cte_series
    WHERE slice_interval IS NOT NULL
    GROUP BY "PatientID"
),

/* top-3 patients by slice-interval range */
top_slice AS (
    SELECT  "PatientID", avg_series_size_mib
    FROM    cte_patient_slice
    ORDER BY slice_interval_diff DESC NULLS LAST
    LIMIT   3
),

/* ---------- exposure range per patient ----------------------- */
cte_patient_exposure AS (
    SELECT
        "PatientID",
        AVG( series_size_bytes ) / (1024*1024.0)                     AS avg_series_size_mib,
        MAX( exposure_value ) - MIN( exposure_value )                AS exposure_diff
    FROM  cte_series
    WHERE exposure_value IS NOT NULL
    GROUP BY "PatientID"
),

/* top-3 patients by exposure range */
top_exposure AS (
    SELECT  "PatientID", avg_series_size_mib
    FROM    cte_patient_exposure
    ORDER BY exposure_diff DESC NULLS LAST
    LIMIT   3
)

/* ---------------- final two-row report ----------------------- */
SELECT 'Top 3 by Slice Interval' AS "Group",
       ROUND( AVG( avg_series_size_mib ), 4 )  AS "AverageSeriesSize_MiB"
FROM   top_slice

UNION ALL

SELECT 'Top 3 by Max Exposure'  AS "Group",
       ROUND( AVG( avg_series_size_mib ), 4 )  AS "AverageSeriesSize_MiB"
FROM   top_exposure;