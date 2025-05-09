/*  STEP‑BY‑STEP LOGIC
    1)  Pull all NLST CT instances.
    2)  Aggregate them to the series level:
           – total size (bytes)
           – one representative slice spacing
           – one representative exposure‑in‑mAs
    3)  For every patient compute
           – slice‑interval tolerance  (max‑min spacing)
           – exposure tolerance       (max‑min exposure)
    4)  Identify the Top‑3 patients for each tolerance.
    5)  For the series that belong to those patients, compute the
        average series size in MiB.
*/

WITH nlst_ct AS (          -- all NLST CT instances
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        "instance_size",
        TRY_TO_DOUBLE("SpacingBetweenSlices")          AS slice_spacing,
        "ExposureInmAs"                                AS exposure_mas
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  "collection_id" = 'nlst'
      AND  "Modality"      = 'CT'
),

series_lvl AS (            -- one row per series
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        SUM("instance_size")                AS series_bytes,
        MIN(slice_spacing)                  AS series_slice_spacing,
        MIN(exposure_mas)                   AS series_exposure_mas
    FROM   nlst_ct
    GROUP  BY "PatientID", "SeriesInstanceUID"
),

patient_tolerances AS (    -- slice‑interval & exposure differences per patient
    SELECT
        "PatientID",
        MAX(series_slice_spacing) - MIN(series_slice_spacing)   AS slice_interval_diff,
        MAX(series_exposure_mas) - MIN(series_exposure_mas)     AS exposure_diff
    FROM   series_lvl
    GROUP  BY "PatientID"
),

top3_slice AS (
    SELECT  "PatientID"
    FROM    patient_tolerances
    WHERE   slice_interval_diff IS NOT NULL
    ORDER BY slice_interval_diff DESC NULLS LAST, "PatientID"
    LIMIT   3
),

top3_exposure AS (
    SELECT  "PatientID"
    FROM    patient_tolerances
    WHERE   exposure_diff IS NOT NULL
    ORDER BY exposure_diff DESC NULLS LAST, "PatientID"
    LIMIT   3
),

slice_series_sizes AS (
    SELECT  series_bytes
    FROM    series_lvl  s
    JOIN    top3_slice  t
           ON s."PatientID" = t."PatientID"
),

exposure_series_sizes AS (
    SELECT  series_bytes
    FROM    series_lvl  s
    JOIN    top3_exposure  t
           ON s."PatientID" = t."PatientID"
)

-- final report
SELECT 'Top 3 by Slice Interval' AS "Group",
       AVG(series_bytes)/(1024*1024)  AS "Average_Series_Size_MiB"
FROM   slice_series_sizes

UNION ALL

SELECT 'Top 3 by Max Exposure'   AS "Group",
       AVG(series_bytes)/(1024*1024)  AS "Average_Series_Size_MiB"
FROM   exposure_series_sizes;