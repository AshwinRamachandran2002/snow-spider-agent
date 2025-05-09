/* ------------------------------------------------------------------
   CT series report that satisfies the requested geometric and
   technical constraints  (Snowflake SQL dialect)
------------------------------------------------------------------ */
WITH filtered AS (  ----------------------------------------------------
    /* instance‑level pre‑filter                                         */
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "StudyInstanceUID",
        "PatientID",
        "SliceThickness",
        "ImagePositionPatient",
        /* use the original FLOAT column; no TRY_CAST needed             */
        "ExposureInmAs"                                 AS exposure_ma,
        "Rows"                                          AS img_rows,
        "Columns"                                       AS img_cols,
        "instance_size",
        TO_VARCHAR("PixelSpacing")                      AS pixel_spacing_str,
        TO_VARCHAR("ImageOrientationPatient")           AS iop_str,
        /* absolute dot product between normal(Z‑axis) and [0,0,1]       */
        ABS(
              ("ImageOrientationPatient"[0]::FLOAT * "ImageOrientationPatient"[4]::FLOAT)
            - ("ImageOrientationPatient"[1]::FLOAT * "ImageOrientationPatient"[3]::FLOAT)
        )                                               AS dot_norm_z
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE  "Modality" = 'CT'
      AND  LOWER("collection_id") <> 'nlst'                               -- exclude NLST
      AND  "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                       '1.2.840.10008.1.2.4.51')          -- skip JPEG
      AND  "ImageType" IS NOT NULL
      AND  NOT (TO_VARCHAR("ImageType") ILIKE '%LOCALIZER%')              -- skip localizers
), ----------------------------------------------------------------------
orientation_ok AS (      /* series passing orientation & spacing checks */
    SELECT
        "SeriesInstanceUID",
        MAX(dot_norm_z)                       AS max_dot,
        MIN(dot_norm_z)                       AS min_dot,
        COUNT(DISTINCT iop_str)               AS n_orient,
        COUNT(DISTINCT pixel_spacing_str)     AS n_pixsp,
        COUNT(DISTINCT img_rows)              AS n_rows,
        COUNT(DISTINCT img_cols)              AS n_cols
    FROM filtered
    GROUP BY "SeriesInstanceUID"
    HAVING  max_dot BETWEEN 0.99 AND 1.01
       AND   min_dot BETWEEN 0.99 AND 1.01
       AND   n_orient = 1
       AND   n_pixsp  = 1
       AND   n_rows   = 1
       AND   n_cols   = 1
), ----------------------------------------------------------------------
pos_counts AS (          /* ensure #instances == #unique positions      */
    SELECT
        "SeriesInstanceUID",
        COUNT(*)                                   AS n_inst,
        COUNT(DISTINCT TO_VARCHAR("ImagePositionPatient")) AS n_pos
    FROM filtered
    GROUP BY "SeriesInstanceUID"
), ----------------------------------------------------------------------
good_series AS (
    SELECT o."SeriesInstanceUID"
    FROM orientation_ok o
    JOIN pos_counts p
      ON p."SeriesInstanceUID" = o."SeriesInstanceUID"
    WHERE p.n_inst = p.n_pos
), ----------------------------------------------------------------------
slice_diffs AS (         /* compute slice‑to‑slice z‑intervals          */
    SELECT
        f.*,
        f."ImagePositionPatient"[2]::FLOAT                              AS z_coord,
        ABS( f."ImagePositionPatient"[2]::FLOAT
             - LAG(f."ImagePositionPatient"[2]::FLOAT)
                 OVER (PARTITION BY f."SeriesInstanceUID"
                       ORDER BY f."ImagePositionPatient"[2]::FLOAT) )   AS z_diff
    FROM filtered f
    WHERE f."SeriesInstanceUID" IN (SELECT "SeriesInstanceUID" FROM good_series)
), ----------------------------------------------------------------------
series_stats AS (        /* aggregate per qualified series              */
    SELECT
        s."SeriesInstanceUID"                                           AS SeriesUID,
        MAX(s."SeriesNumber")                                           AS SeriesNumber,
        MAX(s."StudyInstanceUID")                                       AS StudyUID,
        MAX(s."PatientID")                                              AS PatientID,
        MAX(o.max_dot)                                                  AS max_dot_product,
        COUNT(*)                                                        AS sop_instance_count,
        COUNT(DISTINCT s."SliceThickness")                              AS slice_thickness_count,
        MAX(z_diff)                                                     AS max_slice_interval_diff,
        MIN(z_diff)                                                     AS min_slice_interval_diff,
        MAX(z_diff) - MIN(z_diff)                                       AS slice_interval_tolerance,
        COUNT(DISTINCT s.exposure_ma)                                   AS distinct_exposure_values,
        MAX(s.exposure_ma)                                              AS max_exposure,
        MIN(s.exposure_ma)                                              AS min_exposure,
        MAX(s.exposure_ma) - MIN(s.exposure_ma)                         AS exposure_range,
        ROUND(SUM(s."instance_size")/1048576, 2)                        AS series_size_mib
    FROM slice_diffs s
    JOIN orientation_ok o
      ON o."SeriesInstanceUID" = s."SeriesInstanceUID"
    GROUP BY s."SeriesInstanceUID"
) ----------------------------------------------------------------------
SELECT *
FROM series_stats
ORDER BY
    slice_interval_tolerance DESC NULLS LAST,
    exposure_range           DESC NULLS LAST,
    SeriesUID                DESC;