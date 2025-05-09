WITH filter_ct AS (
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        TRY_TO_NUMBER("SliceThickness")          AS slice_thickness,
        TRY_TO_NUMBER("Exposure")                AS exposure,
        "instance_size"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality"      = 'CT'
      AND "instance_size" IS NOT NULL
),
patient_diff AS (
    /*  slice-interval and exposure span (max-min) per patient  */
    SELECT
        "PatientID",
        MAX(slice_thickness) - MIN(slice_thickness) AS slice_interval_diff,
        MAX(exposure)        - MIN(exposure)        AS exposure_diff
    FROM (
        SELECT DISTINCT "PatientID",
               slice_thickness,
               exposure
        FROM filter_ct
    )
    GROUP BY "PatientID"
),
top_slice_patients AS (
    SELECT "PatientID"
    FROM patient_diff
    ORDER BY slice_interval_diff DESC NULLS LAST
    LIMIT 3
),
top_exposure_patients AS (
    SELECT "PatientID"
    FROM patient_diff
    ORDER BY exposure_diff DESC NULLS LAST
    LIMIT 3
),
series_sizes AS (
    /*  size of every series (MiB)  */
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        SUM("instance_size") / (1024 * 1024.0) AS series_size_mib
    FROM filter_ct
    GROUP BY "PatientID", "SeriesInstanceUID"
),
avg_series_per_patient AS (
    /*  average series size per patient  */
    SELECT
        "PatientID",
        AVG(series_size_mib) AS avg_series_size_mib
    FROM series_sizes
    GROUP BY "PatientID"
),
slice_result AS (
    SELECT
        AVG(avg_series_size_mib) AS avg_series_size_mib
    FROM avg_series_per_patient
    WHERE "PatientID" IN (SELECT "PatientID" FROM top_slice_patients)
),
exposure_result AS (
    SELECT
        AVG(avg_series_size_mib) AS avg_series_size_mib
    FROM avg_series_per_patient
    WHERE "PatientID" IN (SELECT "PatientID" FROM top_exposure_patients)
)
SELECT 'Top 3 by Slice Interval' AS "Group",
       avg_series_size_mib
FROM slice_result

UNION ALL

SELECT 'Top 3 by Max Exposure'  AS "Group",
       avg_series_size_mib
FROM exposure_result;