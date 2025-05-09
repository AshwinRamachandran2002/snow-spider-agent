/* -----------------------------------------------------------
   Compute and compare average series‑size (MiB) for:

   A) Top 3 NLST CT patients with the largest spread in slice
      intervals (max‑min numeric SliceThickness).

   B) Top 3 NLST CT patients with the largest spread in exposure
      (max‑min numeric value from Exposure / ExposureInmAs).

   Result: two rows, each giving the group label and the
           corresponding average series size (MiB).
-----------------------------------------------------------*/
WITH
/* ---------- per‑series size (MiB) ------------------------ */
series_sizes AS (
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        SUM("instance_size")/1048576.0 AS series_mib
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_name" = 'NLST'
      AND "Modality"        = 'CT'
    GROUP BY "PatientID", "SeriesInstanceUID"
),

/* ---------- slice‑interval spread per patient ------------ */
slice_spread AS (
    SELECT
        "PatientID",
        MAX(thk) - MIN(thk) AS slice_diff
    FROM (
        SELECT
            "PatientID",
            TRY_TO_DOUBLE("SliceThickness") AS thk
        FROM IDC.IDC_V17.DICOM_ALL
        WHERE "collection_name" = 'NLST'
          AND "Modality"        = 'CT'
          AND TRY_TO_DOUBLE("SliceThickness") IS NOT NULL
    )
    GROUP BY "PatientID"
),
top3_slice AS (
    SELECT "PatientID"
    FROM (
        SELECT
            "PatientID",
            slice_diff,
            ROW_NUMBER() OVER (ORDER BY slice_diff DESC) AS rn
        FROM slice_spread
    )
    WHERE rn <= 3
),

/* ---------- exposure spread per patient ------------------ */
exposure_spread AS (
    SELECT
        "PatientID",
        MAX(exp) - MIN(exp) AS exp_diff
    FROM (
        SELECT
            "PatientID",
            TRY_TO_DOUBLE(COALESCE("Exposure","ExposureInmAs")) AS exp
        FROM IDC.IDC_V17.DICOM_ALL
        WHERE "collection_name" = 'NLST'
          AND "Modality"        = 'CT'
          AND TRY_TO_DOUBLE(COALESCE("Exposure","ExposureInmAs")) IS NOT NULL
    )
    GROUP BY "PatientID"
),
top3_exposure AS (
    SELECT "PatientID"
    FROM (
        SELECT
            "PatientID",
            exp_diff,
            ROW_NUMBER() OVER (ORDER BY exp_diff DESC) AS rn
        FROM exposure_spread
    )
    WHERE rn <= 3
),

/* ---------- average series size for each group ----------- */
avg_slice_group AS (
    SELECT
        'Top 3 by Slice Interval' AS group_label,
        AVG(series_mib)          AS average_series_mib
    FROM series_sizes
    WHERE "PatientID" IN (SELECT "PatientID" FROM top3_slice)
),
avg_exposure_group AS (
    SELECT
        'Top 3 by Max Exposure'  AS group_label,
        AVG(series_mib)          AS average_series_mib
    FROM series_sizes
    WHERE "PatientID" IN (SELECT "PatientID" FROM top3_exposure)
)

/* ---------- final output --------------------------------- */
SELECT * FROM avg_slice_group
UNION ALL
SELECT * FROM avg_exposure_group;