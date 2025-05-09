WITH ct_instances AS (   --  NLST collection, CT modality only
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        TRY_TO_NUMBER("SpacingBetweenSlices")                AS slice_interval,   --  per‑instance value
        TRY_TO_NUMBER("Exposure")                            AS exposure_value,   --  per‑instance value
        "instance_size"                                      AS inst_bytes
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'nlst'
      AND "Modality" = 'CT'
      AND "instance_size" IS NOT NULL
),
series_level AS (        --  aggregate to series
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        SUM(inst_bytes)/(1024*1024.0)                        AS series_size_mib,      --  MiB
        MAX(slice_interval)                                  AS series_slice_interval, --  one numeric per series
        MAX(exposure_value)                                  AS series_exposure       --  one numeric per series
    FROM ct_instances
    GROUP BY
        "PatientID",
        "SeriesInstanceUID"
),
patient_metrics AS (     --  metrics per patient
    SELECT
        "PatientID",
        AVG(series_size_mib)                                                 AS avg_series_size_mib,
        MAX(series_slice_interval) - MIN(series_slice_interval)              AS slice_interval_diff,
        MAX(series_exposure)       - MIN(series_exposure)                    AS exposure_diff
    FROM series_level
    GROUP BY "PatientID"
),
top3_slice AS (          --  top‑3 by slice‑interval tolerance
    SELECT *
    FROM patient_metrics
    WHERE slice_interval_diff IS NOT NULL
    ORDER BY slice_interval_diff DESC NULLS LAST
    LIMIT 3
),
top3_exposure AS (       --  top‑3 by exposure difference
    SELECT *
    FROM patient_metrics
    WHERE exposure_diff IS NOT NULL
    ORDER BY exposure_diff DESC NULLS LAST
    LIMIT 3
)
SELECT
    'Top 3 by Slice Interval'  AS "Group",
    AVG(avg_series_size_mib)   AS "Average_Series_Size_MiB"
FROM top3_slice

UNION ALL

SELECT
    'Top 3 by Max Exposure'    AS "Group",
    AVG(avg_series_size_mib)   AS "Average_Series_Size_MiB"
FROM top3_exposure;