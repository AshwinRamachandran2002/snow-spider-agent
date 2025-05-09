WITH ct_nlst AS (             -- NLST CT instances
    SELECT *
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality"      = 'CT'
),

/* --------  series‑level size (MiB)  -------- */
per_series AS (
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        SUM("instance_size")/1048576.0                AS series_size_mib
    FROM ct_nlst
    GROUP BY "PatientID", "SeriesInstanceUID"
),

/* --------  patient‑level average series size  -------- */
per_patient_size AS (
    SELECT
        "PatientID",
        AVG(series_size_mib)                          AS avg_series_size_mib
    FROM per_series
    GROUP BY "PatientID"
),

/* --------  patient‑level slice & exposure tolerances  -------- */
per_patient_tol AS (
    SELECT
        "PatientID",
        MAX(TRY_CAST("SliceThickness" AS FLOAT)) - 
        MIN(TRY_CAST("SliceThickness" AS FLOAT))      AS slice_interval_tolerance,
        MAX(TRY_CAST("Exposure"       AS FLOAT)) - 
        MIN(TRY_CAST("Exposure"       AS FLOAT))      AS exposure_tolerance
    FROM ct_nlst
    GROUP BY "PatientID"
),

/* --------  merge size & tolerance metrics  -------- */
per_patient AS (
    SELECT
        s."PatientID",
        s.avg_series_size_mib,
        t.slice_interval_tolerance,
        t.exposure_tolerance
    FROM per_patient_size s
    JOIN per_patient_tol  t
      ON s."PatientID" = t."PatientID"
),

/* --------  average series size of top‑3 patients by slice‑interval tolerance  -------- */
avg_top_slice AS (
    SELECT ROUND(AVG(avg_series_size_mib), 4) AS average_series_size_mib
    FROM (
        SELECT avg_series_size_mib
        FROM per_patient
        ORDER BY slice_interval_tolerance DESC NULLS LAST, "PatientID"
        LIMIT 3
    )
),

/* --------  average series size of top‑3 patients by exposure tolerance  -------- */
avg_top_exposure AS (
    SELECT ROUND(AVG(avg_series_size_mib), 4) AS average_series_size_mib
    FROM (
        SELECT avg_series_size_mib
        FROM per_patient
        ORDER BY exposure_tolerance DESC NULLS LAST, "PatientID"
        LIMIT 3
    )
)

/* --------  final two‑row result  -------- */
SELECT 'Top 3 by Slice Interval' AS group_label,
       average_series_size_mib
FROM avg_top_slice

UNION ALL

SELECT 'Top 3 by Max Exposure'  AS group_label,
       average_series_size_mib
FROM avg_top_exposure;