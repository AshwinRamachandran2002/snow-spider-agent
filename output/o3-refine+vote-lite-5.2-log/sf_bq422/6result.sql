WITH series_stats AS (
    /* 1.  Per–series aggregates for NLST CT instances  */
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        /* total series size in bytes                                             */
        SUM("instance_size")                                  AS series_size_bytes,
        /* one representative slice interval (mm) for the series                 */
        MIN(TRY_TO_NUMBER("SpacingBetweenSlices"))            AS spacing_mm,
        /* one representative exposure value (mAs) for the series                */
        MIN("ExposureInmAs")                                   AS exposure_mas
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality"       = 'CT'
    GROUP BY
        "PatientID",
        "SeriesInstanceUID"
), patient_deltas AS (
    /* 2.  Slice‑interval and exposure ranges per patient                       */
    SELECT
        "PatientID",
        /* slice‑interval tolerance                                              */
        MAX(spacing_mm)  - MIN(spacing_mm)   AS slice_diff_mm,
        /* exposure tolerance                                                   */
        MAX(exposure_mas) - MIN(exposure_mas) AS exposure_diff_mas
    FROM series_stats
    GROUP BY "PatientID"
), top3_slice AS (
    /* 3.  Top 3 patients by slice‑interval tolerance                           */
    SELECT "PatientID"
    FROM patient_deltas
    ORDER BY slice_diff_mm DESC NULLS LAST
    LIMIT 3
), top3_exposure AS (
    /* 4.  Top 3 patients by exposure tolerance                                 */
    SELECT "PatientID"
    FROM patient_deltas
    ORDER BY exposure_diff_mas DESC NULLS LAST
    LIMIT 3
), avg_sizes_slice AS (
    /* 5a. Average series size (MiB) for top slice‑interval patients            */
    SELECT
        AVG(series_size_bytes / 1024.0 / 1024.0) AS avg_series_size_mib
    FROM series_stats s
    JOIN top3_slice t
      ON s."PatientID" = t."PatientID"
), avg_sizes_exposure AS (
    /* 5b. Average series size (MiB) for top exposure‑difference patients       */
    SELECT
        AVG(series_size_bytes / 1024.0 / 1024.0) AS avg_series_size_mib
    FROM series_stats s
    JOIN top3_exposure t
      ON s."PatientID" = t."PatientID"
)
/* 6.  Present results                                                         */
SELECT
    'Top 3 by Slice Interval' AS "Group",
    ROUND(avg_series_size_mib,4) AS "AverageSeriesSize_MiB"
FROM avg_sizes_slice

UNION ALL

SELECT
    'Top 3 by Max Exposure'    AS "Group",
    ROUND(avg_series_size_mib,4) AS "AverageSeriesSize_MiB"
FROM avg_sizes_exposure;