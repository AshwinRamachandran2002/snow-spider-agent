WITH series AS (
    /* 1)  Per–series aggregates (size in MiB, slice interval, exposure)              */
    SELECT
        "PatientID"                       AS patient_id,
        "SeriesInstanceUID"               AS series_uid,
        SUM("instance_size")/1048576.0    AS series_size_mib,          -- bytes→MiB
        MIN( TRY_TO_NUMBER("SpacingBetweenSlices") )  AS slice_interval,
        MIN( "ExposureInmAs" )            AS exposure
    FROM
        IDC.IDC_V17.DICOM_ALL
    WHERE
        "collection_id" = 'nlst'
        AND "Modality" = 'CT'
    GROUP BY
        patient_id,
        series_uid
), patient_metrics AS (
    /* 2)  Per–patient slice-interval and exposure spreads                           */
    SELECT
        patient_id,
        MAX(slice_interval) - MIN(slice_interval)   AS slice_diff,
        MAX(exposure)       - MIN(exposure)         AS exposure_diff
    FROM
        series
    GROUP BY
        patient_id
), top_slice AS (
    /* 3)  Top 3 patients by slice-interval spread                                   */
    SELECT
        patient_id
    FROM
        patient_metrics
    WHERE
        slice_diff IS NOT NULL
    ORDER BY
        slice_diff DESC NULLS LAST
    LIMIT 3
), top_exposure AS (
    /* 4)  Top 3 patients by exposure spread                                         */
    SELECT
        patient_id
    FROM
        patient_metrics
    WHERE
        exposure_diff IS NOT NULL
    ORDER BY
        exposure_diff DESC NULLS LAST
    LIMIT 3
), avg_slice AS (
    /* 5)  Average series size for the top-slice group                               */
    SELECT
        'Top 3 by Slice Interval'          AS group_label,
        AVG(series_size_mib)               AS avg_series_size_mib
    FROM
        series
    WHERE
        patient_id IN (SELECT patient_id FROM top_slice)
), avg_exposure AS (
    /* 6)  Average series size for the top-exposure group                            */
    SELECT
        'Top 3 by Max Exposure'            AS group_label,
        AVG(series_size_mib)               AS avg_series_size_mib
    FROM
        series
    WHERE
        patient_id IN (SELECT patient_id FROM top_exposure)
)
/* 7)  Final result                                                                 */
SELECT * FROM avg_slice
UNION ALL
SELECT * FROM avg_exposure;