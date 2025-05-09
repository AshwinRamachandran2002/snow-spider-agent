WITH series_level AS (       -- CT-series-level metrics for NLST
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        SUM("instance_size")/POWER(1024,2)            AS "series_size_MiB",
        TRY_TO_DOUBLE(MAX("SliceThickness"))          AS "slice_interval_mm",
        TRY_TO_DOUBLE(MAX("Exposure"))                AS "exposure_mAs"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality"      = 'CT'
    GROUP BY
        "PatientID",
        "SeriesInstanceUID"
),
-- ❶ slice-interval span per patient
slice_diff AS (
    SELECT
        "PatientID",
        MAX("slice_interval_mm") - MIN("slice_interval_mm") AS "slice_diff_mm"
    FROM series_level
    WHERE "slice_interval_mm" IS NOT NULL
    GROUP BY "PatientID"
),
top_slice_patients AS (       -- top-3 by slice-interval span
    SELECT "PatientID"
    FROM slice_diff
    ORDER BY "slice_diff_mm" DESC NULLS LAST
    LIMIT 3
),
-- ❷ exposure span per patient
exposure_diff AS (
    SELECT
        "PatientID",
        MAX("exposure_mAs") - MIN("exposure_mAs")     AS "exposure_diff_mAs"
    FROM series_level
    WHERE "exposure_mAs" IS NOT NULL
    GROUP BY "PatientID"
),
top_exposure_patients AS (    -- top-3 by exposure span
    SELECT "PatientID"
    FROM exposure_diff
    ORDER BY "exposure_diff_mAs" DESC NULLS LAST
    LIMIT 3
),
-- average series size (MiB) for the two patient groups
avg_slice AS (
    SELECT AVG("series_size_MiB") AS "avg_series_size_MiB"
    FROM series_level
    WHERE "PatientID" IN (SELECT "PatientID" FROM top_slice_patients)
),
avg_exposure AS (
    SELECT AVG("series_size_MiB") AS "avg_series_size_MiB"
    FROM series_level
    WHERE "PatientID" IN (SELECT "PatientID" FROM top_exposure_patients)
)
-- final report
SELECT 'Top 3 by Slice Interval' AS "Group", "avg_series_size_MiB"
FROM   avg_slice
UNION ALL
SELECT 'Top 3 by Max Exposure'   AS "Group", "avg_series_size_MiB"
FROM   avg_exposure;