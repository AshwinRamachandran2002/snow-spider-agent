/*---------------------------------------------------------------------------
Corrected report of CT image series satisfying the requested geometry /
quality checks – Snowflake SQL
---------------------------------------------------------------------------*/
WITH inst AS (   -- 1. pick CT instances that satisfy basic filters
    SELECT
        "SeriesInstanceUID"                                   AS series_uid ,
        "SeriesNumber"                                        AS series_number ,
        "StudyInstanceUID"                                    AS study_uid ,
        "PatientID"                                           AS patient_id ,
        "ImageOrientationPatient"                             AS iop ,
        "ImagePositionPatient"                                AS ipp ,
        "PixelSpacing"                                        AS ps ,
        "Rows"                                                AS pixel_rows ,
        "Columns"                                             AS pixel_cols ,
        "SliceThickness"                                      AS slice_thickness ,
        "Exposure"                                            AS exposure ,
        "instance_size"                                       AS instance_size ,

        /* individual orientation components --------------------------------*/
        ("ImageOrientationPatient"[0])::FLOAT                 AS r1 ,
        ("ImageOrientationPatient"[1])::FLOAT                 AS r2 ,
        ("ImageOrientationPatient"[2])::FLOAT                 AS r3 ,
        ("ImageOrientationPatient"[3])::FLOAT                 AS c1 ,
        ("ImageOrientationPatient"[4])::FLOAT                 AS c2 ,
        ("ImageOrientationPatient"[5])::FLOAT                 AS c3 ,

        /* individual position components -----------------------------------*/
        ("ImagePositionPatient"[0])::FLOAT                    AS x_pos ,
        ("ImagePositionPatient"[1])::FLOAT                    AS y_pos ,
        ("ImagePositionPatient"[2])::FLOAT                    AS z_pos ,

        /* first two image-position components concatenated -----------------*/
        ARRAY_TO_STRING(
            ARRAY_CONSTRUCT(
                ("ImagePositionPatient"[0])::STRING ,
                ("ImagePositionPatient"[1])::STRING
            ), ','
        )                                                     AS first2_xy
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality"              = 'CT'
      AND "collection_name"      <> 'NLST'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                      '1.2.840.10008.1.2.4.51')
),

/* 2. series that contain a LOCALIZER image -----------------------------------*/
exclude_series AS (
    SELECT DISTINCT "SeriesInstanceUID" AS series_uid
    FROM IDC.IDC_V17.DICOM_PIVOT
    WHERE UPPER("ImageType") LIKE '%LOCALIZER%'
),

/* 3. keep only non-localizer series -----------------------------------------*/
filtered AS (
    SELECT *
    FROM inst
    WHERE series_uid NOT IN (SELECT series_uid FROM exclude_series)
),

/* 4. series-level counts & orientation dot-product --------------------------*/
series_counts AS (
    SELECT
        series_uid,
        MIN(series_number)::TEXT                              AS series_number,
        MIN(study_uid)                                        AS study_uid,
        MIN(patient_id)                                       AS patient_id,

        COUNT(*)                                              AS num_instances,
        COUNT(DISTINCT CAST(ipp AS STRING))                   AS num_dist_ipp,
        COUNT(DISTINCT CAST(iop AS STRING))                   AS num_dist_iop,
        COUNT(DISTINCT CAST(ps  AS STRING))                   AS num_dist_ps,
        COUNT(DISTINCT pixel_rows)                            AS num_dist_rows,
        COUNT(DISTINCT pixel_cols)                            AS num_dist_cols,
        COUNT(DISTINCT first2_xy)                             AS num_dist_first2,
        COUNT(DISTINCT slice_thickness)                       AS num_dist_slice_thick,

        SUM(instance_size)/1048576.0                          AS series_size_mib,

        /* exposure statistics ---------------------------------------------*/
        COUNT(DISTINCT exposure)                              AS num_dist_exposure,
        MAX(TRY_TO_NUMBER(exposure))                          AS max_exposure,
        MIN(TRY_TO_NUMBER(exposure))                          AS min_exposure,

        /* | n·k | where n = r×c , k = [0,0,1]  (only the third component)  */
        MAX( ABS( (r1*c2) - (r2*c1) ) )                       AS max_dot_product
    FROM filtered
    GROUP BY series_uid
),

/* 5. slice-spacing per series -----------------------------------------------*/
z_diffs AS (
    SELECT
        series_uid,
        ABS(z_pos - LAG(z_pos) OVER (PARTITION BY series_uid
                                     ORDER BY z_pos))         AS z_diff
    FROM filtered
    QUALIFY z_diff IS NOT NULL
),

z_agg AS (
    SELECT
        series_uid,
        MAX(z_diff)                                           AS max_slice_interval,
        MIN(z_diff)                                           AS min_slice_interval,
        MAX(z_diff) - MIN(z_diff)                             AS slice_interval_tolerance
    FROM z_diffs
    GROUP BY series_uid
),

/* 6. retain only series passing all geometry checks -------------------------*/
qualified AS (
    SELECT
        sc.series_uid,
        sc.series_number,
        sc.study_uid,
        sc.patient_id,
        sc.max_dot_product,
        sc.num_instances,
        sc.num_dist_slice_thick,
        za.max_slice_interval,
        za.min_slice_interval,
        za.slice_interval_tolerance,
        sc.num_dist_exposure,
        sc.max_exposure,
        sc.min_exposure,
        sc.max_exposure - sc.min_exposure                     AS exposure_range,
        sc.series_size_mib
    FROM series_counts sc
    JOIN z_agg      za ON sc.series_uid = za.series_uid
    WHERE sc.num_instances          = sc.num_dist_ipp
      AND sc.num_dist_iop           = 1
      AND sc.num_dist_ps            = 1
      AND sc.num_dist_rows          = 1
      AND sc.num_dist_cols          = 1
      AND sc.num_dist_first2        = 1
      AND sc.max_dot_product BETWEEN 0.99 AND 1.01
)

/* 7. final ordered report ----------------------------------------------------*/
SELECT
    series_uid                                 AS "SeriesInstanceUID",
    series_number                              AS "SeriesNumber",
    study_uid                                  AS "StudyInstanceUID",
    patient_id                                 AS "PatientID",
    ROUND(max_dot_product,         4)          AS "MaxDotProduct",
    num_instances                              AS "NumSOPInstances",
    num_dist_slice_thick                       AS "DistinctSliceThickness",
    ROUND(max_slice_interval,      4)          AS "MaxSliceIntervalDiff",
    ROUND(min_slice_interval,      4)          AS "MinSliceIntervalDiff",
    ROUND(slice_interval_tolerance,4)          AS "SliceIntervalTolerance",
    num_dist_exposure                          AS "DistinctExposureCount",
    ROUND(max_exposure,            4)          AS "MaxExposure",
    ROUND(min_exposure,            4)          AS "MinExposure",
    ROUND(exposure_range,          4)          AS "ExposureRange",
    ROUND(series_size_mib,         4)          AS "SeriesSizeMiB"
FROM qualified
ORDER BY
      slice_interval_tolerance DESC NULLS LAST ,
      exposure_range           DESC NULLS LAST ,
      series_uid               DESC NULLS LAST ;