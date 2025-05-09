/* -----------------------------------------------------------
   Revised query:  fixes the normal-vector formula so that the
   required |dot-product| test is met and returns data.
------------------------------------------------------------*/
WITH base AS (   -------------------------------------------------
    /*  Basic filters: CT, non-NLST, non-JPEG, non-LOCALIZER   */
    ------------------------------------------------------------
    SELECT
        "SeriesInstanceUID",
        "StudyInstanceUID",
        "PatientID",
        "SeriesNumber",
        "SOPInstanceUID",
        "Rows",
        "Columns",
        "SliceThickness",
        "PixelSpacing",
        "ImageOrientationPatient",
        "ImagePositionPatient",
        TRY_TO_NUMBER("Exposure")                       AS exposure_num,
        "instance_size"
    FROM IDC.IDC_V17."DICOM_ALL"
    WHERE "Modality" = 'CT'
      AND "collection_name" <> 'NLST'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',    -- JPEG-lossless
                                      '1.2.840.10008.1.2.4.51')    -- JPEG-baseline
      AND NOT ("ImageType" ILIKE '%LOCALIZER%')
),
ori AS (          -------------------------------------------------
    /*  Extract the six orientation cosines as DOUBLE           */
    ------------------------------------------------------------
    SELECT
        b.*,
        TRY_TO_DOUBLE((b."ImageOrientationPatient"[0])::STRING) AS rx,
        TRY_TO_DOUBLE((b."ImageOrientationPatient"[1])::STRING) AS ry,
        TRY_TO_DOUBLE((b."ImageOrientationPatient"[2])::STRING) AS rz,
        TRY_TO_DOUBLE((b."ImageOrientationPatient"[3])::STRING) AS cx,
        TRY_TO_DOUBLE((b."ImageOrientationPatient"[4])::STRING) AS cy,
        TRY_TO_DOUBLE((b."ImageOrientationPatient"[5])::STRING) AS cz
    FROM base b
),
geom AS (         -------------------------------------------------
    /*  Cross-product normal & its dot product with (0,0,1)     */
    /*  z-component of R×C  =  rx*cy – ry*cx                    */
    ------------------------------------------------------------
    SELECT
        o.*,
        (o.rx * o.cy - o.ry * o.cx)                    AS nz,
        ABS(o.rx * o.cy - o.ry * o.cx)                 AS abs_dp
    FROM ori o
),
pos AS (          -------------------------------------------------
    /*  Helpers for geometry tests & numeric Z coordinate       */
    ------------------------------------------------------------
    SELECT
        g.*,
        TO_VARCHAR(g."ImageOrientationPatient")            AS orient_str,
        TO_VARCHAR(g."PixelSpacing")                       AS pixsp_str,
        TO_VARCHAR(g."ImagePositionPatient")               AS pos_str,
        TRY_TO_DOUBLE((g."ImagePositionPatient"[0])::STRING) AS x_pos,
        TRY_TO_DOUBLE((g."ImagePositionPatient"[1])::STRING) AS y_pos,
        TRY_TO_DOUBLE((g."ImagePositionPatient"[2])::STRING) AS z_pos
    FROM geom g
),
series_ok AS (    -------------------------------------------------
    /*  Geometry-qualified series                               */
    ------------------------------------------------------------
    SELECT
        "SeriesInstanceUID"                                AS series_uid,
        COUNT(*)                                           AS num_instances,
        COUNT(DISTINCT pos_str)                            AS distinct_pos,
        COUNT(DISTINCT orient_str)                         AS distinct_orient,
        COUNT(DISTINCT pixsp_str)                          AS distinct_pixsp,
        COUNT(DISTINCT x_pos)                              AS distinct_x,
        COUNT(DISTINCT y_pos)                              AS distinct_y,
        COUNT(DISTINCT "Rows")                             AS distinct_rows,
        COUNT(DISTINCT "Columns")                          AS distinct_cols,
        MIN(abs_dp)                                        AS min_abs_dp,
        MAX(abs_dp)                                        AS max_abs_dp
    FROM pos
    GROUP BY "SeriesInstanceUID"
    HAVING  distinct_orient = 1
       AND  distinct_pixsp  = 1
       AND  num_instances   = distinct_pos           -- unique z locations
       AND  distinct_x      = 1                      -- x coordinate fixed
       AND  distinct_y      = 1                      -- y coordinate fixed
       AND  distinct_rows   = 1
       AND  distinct_cols   = 1
       AND  min_abs_dp     >= 0.99                  -- alignment criterion
),
slice_stats AS (  -------------------------------------------------
    /*  Slice-interval (Δz) statistics                          */
    ------------------------------------------------------------
    SELECT
        series_uid,
        MIN(delta)                                   AS min_slice_interval,
        MAX(delta)                                   AS max_slice_interval,
        MAX(delta) - MIN(delta)                      AS slice_tolerance
    FROM (
        SELECT
            "SeriesInstanceUID" AS series_uid,
            ABS(z_pos - LAG(z_pos) OVER (PARTITION BY "SeriesInstanceUID"
                                         ORDER BY z_pos)) AS delta
        FROM pos
    )
    WHERE delta IS NOT NULL
    GROUP BY series_uid
),
expo AS (         -------------------------------------------------
    /*  Exposure statistics per series                          */
    ------------------------------------------------------------
    SELECT
        "SeriesInstanceUID"                           AS series_uid,
        COUNT(DISTINCT exposure_num)                  AS distinct_exposure,
        MIN(exposure_num)                             AS min_exposure,
        MAX(exposure_num)                             AS max_exposure,
        MAX(exposure_num) - MIN(exposure_num)         AS exposure_range
    FROM pos
    GROUP BY "SeriesInstanceUID"
),
report AS (       -------------------------------------------------
    /*  Assemble final report                                   */
    ------------------------------------------------------------
    SELECT
        p."SeriesInstanceUID"                         AS "SeriesInstanceUID",
        MIN(p."SeriesNumber")                         AS "SeriesNumber",
        MIN(p."StudyInstanceUID")                     AS "StudyInstanceUID",
        MIN(p."PatientID")                            AS "PatientID",
        s.max_abs_dp                                  AS "MaxDotProduct",
        s.num_instances                               AS "NumSOPInstances",
        COUNT(DISTINCT p."SliceThickness")            AS "DistinctSliceThickness",
        sl.max_slice_interval                         AS "MaxSliceInterval",
        sl.min_slice_interval                         AS "MinSliceInterval",
        sl.slice_tolerance                            AS "SliceIntervalTolerance",
        ex.distinct_exposure                          AS "DistinctExposureValues",
        ex.max_exposure                               AS "MaxExposure",
        ex.min_exposure                               AS "MinExposure",
        ex.exposure_range                             AS "ExposureRange",
        ROUND(SUM(p."instance_size") / 1048576, 4)    AS "SeriesSize_MiB"
    FROM pos p
    JOIN series_ok   s  ON p."SeriesInstanceUID" = s.series_uid
    JOIN slice_stats sl ON p."SeriesInstanceUID" = sl.series_uid
    LEFT JOIN expo   ex ON p."SeriesInstanceUID" = ex.series_uid
    GROUP BY
        p."SeriesInstanceUID",
        s.max_abs_dp,
        s.num_instances,
        sl.max_slice_interval,
        sl.min_slice_interval,
        sl.slice_tolerance,
        ex.distinct_exposure,
        ex.max_exposure,
        ex.min_exposure,
        ex.exposure_range
)
SELECT *
FROM   report
ORDER BY "SliceIntervalTolerance" DESC NULLS LAST,
         "ExposureRange"          DESC NULLS LAST,
         "SeriesInstanceUID"      DESC;