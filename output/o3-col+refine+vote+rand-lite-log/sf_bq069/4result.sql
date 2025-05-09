/*  Report of qualified CT image series – fix GROUP BY aggregation of dz values  */
WITH base AS (   /* ----------------------------------------------------------------
                    1. keep CT instances, drop NLST, skip JPEG-compressed syntaxes
                 -----------------------------------------------------------------*/
    SELECT
        t."SeriesInstanceUID",
        t."SeriesNumber",
        t."StudyInstanceUID",
        t."PatientID",
        t."SOPInstanceUID",
        t."Rows",
        t."Columns",
        TRY_TO_NUMBER(t."SliceThickness")                               AS slice_thick,
        TRY_TO_NUMBER(t."Exposure")                                     AS exposure_val,
        /* -------- geometry ---------------------------------------------------- */
        TRY_TO_NUMBER((t."ImagePositionPatient")[0]::STRING)            AS x_pos,
        TRY_TO_NUMBER((t."ImagePositionPatient")[1]::STRING)            AS y_pos,
        TRY_TO_NUMBER((t."ImagePositionPatient")[2]::STRING)            AS z_pos,
        TO_VARCHAR(t."ImagePositionPatient")                            AS z_pos_str,
        TO_VARCHAR(t."ImageOrientationPatient")                         AS orient_str,
        TO_VARCHAR(t."PixelSpacing")                                    AS pixspace_str,
        TRY_TO_NUMBER((t."ImageOrientationPatient")[0]::STRING)         AS o1,
        TRY_TO_NUMBER((t."ImageOrientationPatient")[1]::STRING)         AS o2,
        TRY_TO_NUMBER((t."ImageOrientationPatient")[3]::STRING)         AS o4,
        TRY_TO_NUMBER((t."ImageOrientationPatient")[4]::STRING)         AS o5,
        t."instance_size"
    FROM IDC.IDC_V17.DICOM_ALL t
    WHERE t."Modality"           = 'CT'
      AND t."collection_name"   <> 'NLST'
      AND t."TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',        /* JPEG-Lossless */
                                        '1.2.840.10008.1.2.4.51')        /* JPEG-Baseline */
),
/* -------------------------------------------------------------------------------
   2. flag LOCALIZER series
   -----------------------------------------------------------------------------*/
localizer_flag AS (
    SELECT
        t."SeriesInstanceUID",
        MAX(CASE WHEN UPPER(TRIM(f.value::STRING)) = 'LOCALIZER' THEN 1 ELSE 0 END)
            AS has_localizer
    FROM IDC.IDC_V17.DICOM_ALL t,
         LATERAL FLATTEN(input => t."ImageType") f
    WHERE t."Modality"           = 'CT'
      AND t."collection_name"   <> 'NLST'
      AND t."TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                        '1.2.840.10008.1.2.4.51')
    GROUP BY t."SeriesInstanceUID"
),
/* -------------------------------------------------------------------------------
   3. per-instance orientation quality
   -----------------------------------------------------------------------------*/
per_instance AS (
    SELECT
        b.*,
        ABS( (b.o1 * b.o5) - (b.o2 * b.o4) )                        AS abs_dot
    FROM base b
),
/* -------------------------------------------------------------------------------
   4. slice-to-slice Δz per series
   -----------------------------------------------------------------------------*/
z_intervals AS (
    SELECT
        "SeriesInstanceUID",
        ABS( LEAD(z_pos) OVER (PARTITION BY "SeriesInstanceUID"
                               ORDER BY z_pos) - z_pos )            AS dz
    FROM per_instance
),
z_summary AS (
    SELECT
        "SeriesInstanceUID",
        MAX(dz)                                                     AS max_dz,
        MIN(dz)                                                     AS min_dz
    FROM z_intervals
    WHERE dz IS NOT NULL
    GROUP BY "SeriesInstanceUID"
),
/* -------------------------------------------------------------------------------
   5. series-level metrics (aggregate)
   -----------------------------------------------------------------------------*/
series_metrics AS (
    SELECT
        pi."SeriesInstanceUID",
        MIN(pi."SeriesNumber")                                      AS series_number,
        MIN(pi."StudyInstanceUID")                                  AS study_uid,
        MIN(pi."PatientID")                                         AS patient_id,
        MAX(pi.abs_dot)                                             AS max_abs_dot,
        COUNT(*)                                                    AS num_instances,
        COUNT(DISTINCT pi.slice_thick)                              AS n_slice_thick,
        MAX(zs.max_dz)                                              AS max_dz,
        MIN(zs.min_dz)                                              AS min_dz,
        MAX(zs.max_dz) - MIN(zs.min_dz)                             AS dz_tolerance,
        COUNT(DISTINCT pi.exposure_val)                             AS n_exposures,
        MAX(pi.exposure_val)                                        AS max_exposure,
        MIN(pi.exposure_val)                                        AS min_exposure,
        MAX(pi.exposure_val) - MIN(pi.exposure_val)                 AS exposure_range,
        SUM(pi."instance_size") / 1048576.0                         AS size_mib,
        /* geometry consistency counts -----------------------------*/
        COUNT(DISTINCT pi.orient_str)                               AS n_orient,
        COUNT(DISTINCT pi.pixspace_str)                             AS n_pixspace,
        COUNT(DISTINCT pi.z_pos_str)                                AS n_z,
        COUNT(DISTINCT pi.x_pos)                                    AS n_x,
        COUNT(DISTINCT pi.y_pos)                                    AS n_y,
        COUNT(DISTINCT pi."Rows")                                   AS n_rows,
        COUNT(DISTINCT pi."Columns")                                AS n_cols
    FROM per_instance pi
    LEFT JOIN z_summary zs
           ON pi."SeriesInstanceUID" = zs."SeriesInstanceUID"
    GROUP BY pi."SeriesInstanceUID"
),
/* -------------------------------------------------------------------------------
   6. apply geometry / quality filters
   -----------------------------------------------------------------------------*/
qualified AS (
    SELECT sm.*
    FROM series_metrics sm
    JOIN localizer_flag lf
      ON sm."SeriesInstanceUID" = lf."SeriesInstanceUID"
    WHERE lf.has_localizer = 0
      AND sm.n_orient      = 1
      AND sm.n_pixspace    = 1
      AND sm.num_instances = sm.n_z
      AND sm.n_x           = 1
      AND sm.n_y           = 1
      AND sm.n_rows        = 1
      AND sm.n_cols        = 1
      AND sm.max_abs_dot  >= 0.99
)
/* -------------------------------------------------------------------------------
   7. final report
   -----------------------------------------------------------------------------*/
SELECT
    "SeriesInstanceUID"                       AS "series_uid",
    series_number                             AS "series_number",
    study_uid                                 AS "study_uid",
    patient_id                                AS "patient_id",
    ROUND(max_abs_dot, 6)                     AS "max_abs_dot_product",
    num_instances                             AS "num_sop_instances",
    n_slice_thick                             AS "num_distinct_slice_thickness",
    ROUND(max_dz, 6)                          AS "max_slice_interval",
    ROUND(min_dz, 6)                          AS "min_slice_interval",
    ROUND(dz_tolerance, 6)                    AS "slice_interval_tolerance",
    n_exposures                               AS "num_distinct_exposures",
    max_exposure                              AS "max_exposure",
    min_exposure                              AS "min_exposure",
    exposure_range                            AS "exposure_range",
    ROUND(size_mib, 4)                        AS "series_size_mib"
FROM qualified
ORDER BY "slice_interval_tolerance" DESC NULLS LAST,
         exposure_range              DESC NULLS LAST,
         "series_uid"                DESC;