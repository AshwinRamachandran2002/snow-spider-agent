/* 1)  Prepare one row per series containing:
      - patient id
      - series size in MiB
      - a representative slice‐interval value
      - a representative exposure-in-mAs value                                             */
WITH series_level AS (
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        /* series size in MiB = Σ(instance_size) / 1 048 576 */
        SUM("instance_size")/1048576.0                               AS series_size_mib,
        /* take one (non-null) slice-interval value for the series   */
        MIN( CAST( NULLIF("SpacingBetweenSlices",'') AS FLOAT) )
            AS spacing_between_slices_mm,
        /* take one (non-null) exposure-in-mAs value for the series  */
        MIN( "ExposureInmAs" )                                       AS exposure_mAs
    FROM  IDC.IDC_V17.DICOM_ALL
    WHERE
           "collection_id" = 'nlst'
       AND "Modality"      = 'CT'
    GROUP BY
        "PatientID",
        "SeriesInstanceUID"
),

/* 2)  Aggregate to the patient level                                     */
patient_level AS (
    SELECT
        "PatientID",
        /* difference between max & min unique slice intervals             */
        MAX(spacing_between_slices_mm) - MIN(spacing_between_slices_mm)
            AS slice_interval_diff_mm,
        /* difference between max & min unique exposure values             */
        MAX(exposure_mAs)               - MIN(exposure_mAs)
            AS exposure_diff_mAs,
        /* patient’s average series size                                   */
        AVG(series_size_mib)            AS avg_series_size_mib
    FROM series_level
    GROUP BY "PatientID"
),

/* 3)  Pick the 3 patients with the largest slice-interval difference      */
top3_slice   AS (
    SELECT avg_series_size_mib
    FROM   patient_level
    WHERE  slice_interval_diff_mm IS NOT NULL
    ORDER BY slice_interval_diff_mm DESC NULLS LAST
    LIMIT 3
),

/* 4)  Pick the 3 patients with the largest exposure difference            */
top3_exposure AS (
    SELECT avg_series_size_mib
    FROM   patient_level
    WHERE  exposure_diff_mAs IS NOT NULL
    ORDER BY exposure_diff_mAs   DESC NULLS LAST
    LIMIT 3
)

/* 5)  Return the requested two metrics                                    */
SELECT
    'Top 3 by Slice Interval'  AS group_label,
    AVG(avg_series_size_mib)   AS average_series_size_mib
FROM top3_slice

UNION ALL

SELECT
    'Top 3 by Max Exposure'    AS group_label,
    AVG(avg_series_size_mib)   AS average_series_size_mib
FROM top3_exposure;