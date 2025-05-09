WITH base AS (   -- NLST CT instances only
    SELECT 
        "PatientID",
        "SeriesInstanceUID",
        "SliceThickness",
        "Exposure",
        "instance_size"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality" = 'CT'
),
-- per–series size in bytes
series_sizes AS (
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        SUM("instance_size")                           AS series_bytes
    FROM base
    GROUP BY "PatientID","SeriesInstanceUID"
),
-- average series size (MiB) per patient
patient_series_avg AS (
    SELECT
        "PatientID",
        AVG(series_bytes / 1024.0 / 1024.0)            AS avg_series_mib
    FROM series_sizes
    GROUP BY "PatientID"
),
-- numeric slice–interval values per patient
slice_vals AS (
    SELECT
        "PatientID",
        TRY_TO_NUMBER(TRIM("SliceThickness"))          AS slice_thickness
    FROM base
    WHERE TRIM(COALESCE("SliceThickness",'')) <> ''
      AND TRY_TO_NUMBER(TRIM("SliceThickness")) IS NOT NULL
),
-- per-patient slice-interval range
slice_diffs AS (
    SELECT
        "PatientID",
        MAX(slice_thickness) - MIN(slice_thickness)    AS slice_diff
    FROM slice_vals
    GROUP BY "PatientID"
),
-- top-3 patients by greatest slice-interval range
top_slice_patients AS (
    SELECT "PatientID"
    FROM slice_diffs
    ORDER BY slice_diff DESC NULLS LAST
    LIMIT 3
),
-- numeric exposure values per patient
exposure_vals AS (
    SELECT
        "PatientID",
        TRY_TO_NUMBER(TRIM("Exposure"))                AS exposure_val
    FROM base
    WHERE TRIM(COALESCE("Exposure",'')) <> ''
      AND TRY_TO_NUMBER(TRIM("Exposure")) IS NOT NULL
),
-- per-patient exposure range
exposure_diffs AS (
    SELECT
        "PatientID",
        MAX(exposure_val) - MIN(exposure_val)          AS exposure_diff
    FROM exposure_vals
    GROUP BY "PatientID"
),
-- top-3 patients by greatest exposure range
top_exposure_patients AS (
    SELECT "PatientID"
    FROM exposure_diffs
    ORDER BY exposure_diff DESC NULLS LAST
    LIMIT 3
),
-- group-level average (across the 3 patients) for slice-interval group
slice_group_avg AS (
    SELECT
        AVG(pa.avg_series_mib)                         AS group_avg_mib
    FROM patient_series_avg pa
    JOIN top_slice_patients tp USING ("PatientID")
),
-- group-level average (across the 3 patients) for exposure group
exposure_group_avg AS (
    SELECT
        AVG(pa.avg_series_mib)                         AS group_avg_mib
    FROM patient_series_avg pa
    JOIN top_exposure_patients te USING ("PatientID")
)
-- final two-row result
SELECT 
    'Top 3 by Slice Interval'  AS group_label,
    ROUND(group_avg_mib,4)     AS avg_series_size_mib
FROM slice_group_avg

UNION ALL

SELECT 
    'Top 3 by Max Exposure'    AS group_label,
    ROUND(group_avg_mib,4)     AS avg_series_size_mib
FROM exposure_group_avg;