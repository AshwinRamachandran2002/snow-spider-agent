WITH series_level AS (            -- 1. CT series in NLST collection
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        SUM("instance_size")                              AS series_bytes,            -- size of the series
        MAX(TRY_CAST("SliceThickness" AS FLOAT))          AS slice_thickness,         -- one value per series
        MAX(TRY_CAST("Exposure"       AS FLOAT))          AS exposure                 -- one value per series
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality"      = 'CT'
    GROUP BY
        "PatientID",
        "SeriesInstanceUID"
),

series_mib AS (                 -- 2. convert series size to MiB
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        series_bytes / 1048576.0                       AS series_mib,
        slice_thickness,
        exposure
    FROM series_level
),

patient_slice_span AS (         -- 3. per–patient slice-interval span
    SELECT
        "PatientID",
        MAX(slice_thickness) - MIN(slice_thickness)    AS slice_span
    FROM series_mib
    WHERE slice_thickness IS NOT NULL
    GROUP BY "PatientID"
),

patient_exposure_span AS (      -- 4. per–patient exposure span
    SELECT
        "PatientID",
        MAX(exposure) - MIN(exposure)                  AS exposure_span
    FROM series_mib
    WHERE exposure IS NOT NULL
    GROUP BY "PatientID"
),

top3_slice_patients AS (        -- 5. top-3 patients by slice span
    SELECT  "PatientID"
    FROM    patient_slice_span
    QUALIFY ROW_NUMBER() OVER(ORDER BY slice_span DESC NULLS LAST) <= 3
),

top3_exposure_patients AS (     -- 6. top-3 patients by exposure span
    SELECT  "PatientID"
    FROM    patient_exposure_span
    QUALIFY ROW_NUMBER() OVER(ORDER BY exposure_span DESC NULLS LAST) <= 3
),

avg_size_slice AS (             -- 7. average series size for top slice-span patients
    SELECT
        ROUND(AVG(series_mib),4) AS avg_series_mib
    FROM series_mib
    WHERE "PatientID" IN (SELECT "PatientID" FROM top3_slice_patients)
),

avg_size_exposure AS (          -- 8. average series size for top exposure-span patients
    SELECT
        ROUND(AVG(series_mib),4) AS avg_series_mib
    FROM series_mib
    WHERE "PatientID" IN (SELECT "PatientID" FROM top3_exposure_patients)
)

-- 9. final report
SELECT 'Top 3 by Slice Interval' AS "Group", avg_series_mib
FROM   avg_size_slice
UNION ALL
SELECT 'Top 3 by Max Exposure'   AS "Group", avg_series_mib
FROM   avg_size_exposure;