WITH nlst_ct AS (                               -- 1)  NLST CT instances
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        "instance_size",
        TRY_TO_DOUBLE("SliceThickness") AS slice_thickness_mm,
        TRY_TO_DOUBLE("ExposureInmAs")  AS exposure_mAs
    FROM IDC.IDC_V17."DICOM_ALL"
    WHERE "collection_id" = 'nlst'
      AND "Modality"      = 'CT'
),

-- 2) Series-level total size (MiB)
series_sizes AS (
    SELECT
        "SeriesInstanceUID",
        ANY_VALUE("PatientID")                    AS "PatientID",
        SUM("instance_size")/1024.0/1024.0        AS series_size_MiB
    FROM nlst_ct
    GROUP BY "SeriesInstanceUID"
),

-- 3) Series-level slice spacing (mm)
series_spacing AS (
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        MIN(slice_thickness_mm)                   AS slice_spacing_mm
    FROM nlst_ct
    WHERE slice_thickness_mm IS NOT NULL
    GROUP BY "PatientID", "SeriesInstanceUID"
),

-- 4) Top-3 patients by slice-spacing tolerance
patient_slice_top3 AS (
    SELECT "PatientID"
    FROM (
        SELECT
            "PatientID",
            MAX(slice_spacing_mm) - MIN(slice_spacing_mm) AS slice_tol
        FROM series_spacing
        GROUP BY "PatientID"
        HAVING slice_tol IS NOT NULL
        ORDER BY slice_tol DESC NULLS LAST
        LIMIT 3
    )
),

-- 5) Series-level exposure (mAs)
series_exposure AS (
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        MIN(exposure_mAs)                         AS exposure_mAs
    FROM nlst_ct
    WHERE exposure_mAs IS NOT NULL
    GROUP BY "PatientID", "SeriesInstanceUID"
),

-- 6) Top-3 patients by exposure tolerance
patient_expo_top3 AS (
    SELECT "PatientID"
    FROM (
        SELECT
            "PatientID",
            MAX(exposure_mAs) - MIN(exposure_mAs) AS exposure_tol
        FROM series_exposure
        GROUP BY "PatientID"
        HAVING exposure_tol IS NOT NULL
        ORDER BY exposure_tol DESC NULLS LAST
        LIMIT 3
    )
),

-- 7) Average series size for each group
avg_size_slice AS (
    SELECT AVG(series_size_MiB) AS avg_series_size_MiB
    FROM series_sizes
    WHERE "PatientID" IN (SELECT "PatientID" FROM patient_slice_top3)
),
avg_size_expo  AS (
    SELECT AVG(series_size_MiB) AS avg_series_size_MiB
    FROM series_sizes
    WHERE "PatientID" IN (SELECT "PatientID" FROM patient_expo_top3)
)

-- 8) Final two-row result
SELECT 'Top 3 by Slice Interval' AS "Group_Label",
       (SELECT avg_series_size_MiB FROM avg_size_slice) AS "avg_series_size_MiB"
UNION ALL
SELECT 'Top 3 by Max Exposure'   AS "Group_Label",
       (SELECT avg_series_size_MiB FROM avg_size_expo)  AS "avg_series_size_MiB";