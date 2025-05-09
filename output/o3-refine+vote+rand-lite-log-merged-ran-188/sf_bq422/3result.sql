/*  Average NLST-CT series size (MiB) for two patient cohorts:
    ▸ Top-3 patients with largest slice-interval (SliceThickness) range
    ▸ Top-3 patients with largest exposure (ExposureInmAs) range                                   */
WITH ct_nlst AS (   /* All NLST CT instances – keep only needed columns */
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        "SliceThickness",
        "ExposureInmAs",
        "instance_size"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality"      = 'CT'
),

/* ── 1. Range of slice interval per patient ──────────────────────────────────────────────── */
slice_diff_per_patient AS (
    SELECT
        "PatientID",
        MAX(TRY_TO_NUMBER("SliceThickness"::STRING))
      - MIN(TRY_TO_NUMBER("SliceThickness"::STRING))  AS slice_diff
    FROM ct_nlst
    WHERE "SliceThickness" IS NOT NULL
    GROUP BY "PatientID"
),
top3_slice AS (
    SELECT "PatientID"
    FROM   slice_diff_per_patient
    ORDER  BY slice_diff DESC NULLS LAST
    LIMIT  3
),

/* ── 2. Range of exposure per patient ────────────────────────────────────────────────────── */
exposure_diff_per_patient AS (
    SELECT
        "PatientID",
        MAX(TRY_TO_NUMBER("ExposureInmAs"::STRING))
      - MIN(TRY_TO_NUMBER("ExposureInmAs"::STRING))   AS exp_diff
    FROM ct_nlst
    WHERE "ExposureInmAs" IS NOT NULL
    GROUP BY "PatientID"
),
top3_exposure AS (
    SELECT "PatientID"
    FROM   exposure_diff_per_patient
    ORDER  BY exp_diff DESC NULLS LAST
    LIMIT  3
),

/* ── 3. Series-level size (MiB) ──────────────────────────────────────────────────────────── */
series_sizes AS (
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        SUM("instance_size") / (1024*1024) AS series_size_mib
    FROM ct_nlst
    GROUP BY "PatientID", "SeriesInstanceUID"
),

/* ── 4. Average series size per patient in each cohort ───────────────────────────────────── */
avg_size_slice AS (
    SELECT
        'Top 3 by Slice Interval' AS "Group",
        ss."PatientID",
        AVG(series_size_mib)      AS avg_series_size_mib
    FROM series_sizes ss
    JOIN top3_slice ts
      ON ss."PatientID" = ts."PatientID"
    GROUP BY ss."PatientID"
),
avg_size_exposure AS (
    SELECT
        'Top 3 by Max Exposure'   AS "Group",
        ss."PatientID",
        AVG(series_size_mib)      AS avg_series_size_mib
    FROM series_sizes ss
    JOIN top3_exposure te
      ON ss."PatientID" = te."PatientID"
    GROUP BY ss."PatientID"
)

/* ── 5. Final combined result ────────────────────────────────────────────────────────────── */
SELECT * FROM avg_size_slice
UNION ALL
SELECT * FROM avg_size_exposure
ORDER BY "Group", avg_series_size_mib DESC;