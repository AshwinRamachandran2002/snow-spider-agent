WITH ct_data AS (
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        TRY_TO_DOUBLE(
            COALESCE(
                NULLIF("SpacingBetweenSlices", ''),
                NULLIF("SliceThickness", '')
            )
        )                                              AS slice_interval,
        TRY_TO_DOUBLE(NULLIF("Exposure", ''))         AS exposure_value,
        "instance_size"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality"       = 'CT'
),
-- size of every CT series (MiB)
series_sizes AS (
    SELECT
        "SeriesInstanceUID",
        "PatientID",
        SUM("instance_size") / (1024 * 1024)          AS series_size_mib
    FROM ct_data
    GROUP BY "SeriesInstanceUID", "PatientID"
),
-- average series size per patient
patient_series_avg AS (
    SELECT
        "PatientID",
        AVG(series_size_mib)                          AS patient_avg_series_size_mib
    FROM series_sizes
    GROUP BY "PatientID"
),
-- slice‑interval range per patient
patient_slice_diff AS (
    SELECT
        "PatientID",
        MAX(slice_interval) - MIN(slice_interval)     AS diff_slice
    FROM ct_data
    WHERE slice_interval IS NOT NULL
    GROUP BY "PatientID"
),
-- exposure range per patient
patient_exposure_diff AS (
    SELECT
        "PatientID",
        MAX(exposure_value) - MIN(exposure_value)     AS diff_exposure
    FROM ct_data
    WHERE exposure_value IS NOT NULL
    GROUP BY "PatientID"
),
-- 3 patients with largest slice‑interval range
top_slice_patients AS (
    SELECT "PatientID"
    FROM patient_slice_diff
    ORDER BY diff_slice DESC NULLS LAST, "PatientID"
    LIMIT 3
),
-- 3 patients with largest exposure range
top_exposure_patients AS (
    SELECT "PatientID"
    FROM patient_exposure_diff
    ORDER BY diff_exposure DESC NULLS LAST, "PatientID"
    LIMIT 3
),
slice_group AS (
    SELECT
        'Top 3 by Slice Interval'                     AS group_label,
        ROUND(AVG(p.patient_avg_series_size_mib), 4)  AS average_series_size_mib
    FROM top_slice_patients t
    JOIN patient_series_avg p
      ON p."PatientID" = t."PatientID"
),
exposure_group AS (
    SELECT
        'Top 3 by Max Exposure'                      AS group_label,
        ROUND(AVG(p.patient_avg_series_size_mib), 4) AS average_series_size_mib
    FROM top_exposure_patients t
    JOIN patient_series_avg p
      ON p."PatientID" = t."PatientID"
)
SELECT * FROM slice_group
UNION ALL
SELECT * FROM exposure_group
ORDER BY group_label;