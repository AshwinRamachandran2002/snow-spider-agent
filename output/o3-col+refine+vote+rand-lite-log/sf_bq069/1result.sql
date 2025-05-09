/*  Corrected report – removes quoted alias so ORDER BY works              */

WITH filtered AS (      -- basic modality / collection / compression / localizer filters
    SELECT *
    FROM   "IDC"."IDC_V17"."DICOM_ALL"
    WHERE  "Modality" = 'CT'
      AND  "collection_name" <> 'NLST'
      AND  "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',   -- JPEG-Lossless
                                       '1.2.840.10008.1.2.4.51')   -- JPEG-Baseline
      AND  "ImageType" NOT ILIKE '%LOCALIZER%'
),
geom_prep AS (          -- extract numeric / string pieces from VARIANT columns
    SELECT
        f.*,
        /* orientation components (row-cosines r1-r3, column-cosines c1-c3) */
        TO_DOUBLE(f."ImageOrientationPatient"[0]) AS r1,
        TO_DOUBLE(f."ImageOrientationPatient"[1]) AS r2,
        TO_DOUBLE(f."ImageOrientationPatient"[2]) AS r3,
        TO_DOUBLE(f."ImageOrientationPatient"[3]) AS c1,
        TO_DOUBLE(f."ImageOrientationPatient"[4]) AS c2,
        TO_DOUBLE(f."ImageOrientationPatient"[5]) AS c3,
        /* z-coordinate plus x/y strings */
        TO_DOUBLE(f."ImagePositionPatient"[2])    AS pos_z,
        TO_VARCHAR(f."ImagePositionPatient"[0])   AS pos_x_str,
        TO_VARCHAR(f."ImagePositionPatient"[1])   AS pos_y_str,
        /* handy string representations for equality checks */
        TO_VARCHAR(f."ImageOrientationPatient")   AS orientation_str,
        TO_VARCHAR(f."PixelSpacing")              AS pixelspacing_str,
        TO_VARCHAR(f."ImagePositionPatient")      AS position_str,
        /* numeric exposure */
        TRY_TO_NUMBER(f."Exposure")               AS exposure_num,
        /* z-component of cross-product of orientation vectors */
        ( TO_DOUBLE(f."ImageOrientationPatient"[0]) * TO_DOUBLE(f."ImageOrientationPatient"[4])
        - TO_DOUBLE(f."ImageOrientationPatient"[1]) * TO_DOUBLE(f."ImageOrientationPatient"[3]) )
                                                  AS cross_z
    FROM filtered f
),
series_level AS (       -- per-series aggregation with geometry checks
    SELECT
        "SeriesInstanceUID",
        MAX("SeriesNumber")                        AS series_number,
        MAX("StudyInstanceUID")                    AS study_uid,
        MAX("PatientID")                           AS patient_id,

        MAX(ABS(cross_z))                          AS max_dot_product,
        MIN(ABS(cross_z))                          AS min_dot_product,

        COUNT(*)                                   AS n_instances,
        COUNT(DISTINCT orientation_str)            AS n_orientations,
        COUNT(DISTINCT pixelspacing_str)           AS n_pixel_spacings,
        COUNT(DISTINCT position_str)               AS n_positions,
        COUNT(DISTINCT pos_x_str||','||pos_y_str)  AS n_xy_pairs,
        COUNT(DISTINCT "Rows")                     AS n_rows,
        COUNT(DISTINCT "Columns")                  AS n_cols,

        COUNT(DISTINCT "SliceThickness")           AS n_slice_thk,
        COUNT(DISTINCT exposure_num)               AS n_exposure,
        MIN(exposure_num)                          AS min_exposure,
        MAX(exposure_num)                          AS max_exposure,
        SUM("instance_size")/1048576.0             AS series_size_mib
    FROM   geom_prep
    GROUP  BY "SeriesInstanceUID"
    HAVING  n_orientations      = 1      -- identical orientation
       AND  n_pixel_spacings    = 1      -- identical pixel spacing
       AND  n_rows              = 1      -- identical rows
       AND  n_cols              = 1      -- identical columns
       AND  n_xy_pairs          = 1      -- same first two pos components
       AND  n_instances         = n_positions  -- #instances == #unique positions
       AND  min_dot_product     >= 0.99 -- cross-product aligned with Z
),
z_diffs AS (            -- Δz between consecutive slices per series
    SELECT
        gp."SeriesInstanceUID",
        ABS(pos_z - LAG(pos_z) OVER (PARTITION BY gp."SeriesInstanceUID"
                                     ORDER BY pos_z)) AS dz
    FROM   geom_prep gp
    JOIN   series_level sl
          ON gp."SeriesInstanceUID" = sl."SeriesInstanceUID"
),
z_stats AS (            -- min / max Δz and tolerance per series
    SELECT
        "SeriesInstanceUID",
        MAX(dz)                        AS max_z_diff,
        MIN(dz)                        AS min_z_diff,
        MAX(dz) - MIN(dz)              AS z_diff_tolerance
    FROM   z_diffs
    WHERE  dz IS NOT NULL
    GROUP  BY "SeriesInstanceUID"
)
SELECT
    sl."SeriesInstanceUID"             AS series_uid,
    sl.series_number,
    sl.study_uid,
    sl.patient_id,
    ROUND(sl.max_dot_product, 5)       AS max_dot_product,
    sl.n_instances                     AS num_sop_instances,
    sl.n_slice_thk                     AS num_distinct_slice_thickness,
    zs.max_z_diff                      AS max_slice_interval,
    zs.min_z_diff                      AS min_slice_interval,
    zs.z_diff_tolerance                AS slice_interval_tolerance,
    sl.n_exposure                      AS num_distinct_exposure,
    sl.max_exposure,
    sl.min_exposure,
    sl.max_exposure - sl.min_exposure  AS exposure_range,
    ROUND(sl.series_size_mib, 2)       AS series_size_mib
FROM   series_level sl
LEFT   JOIN z_stats zs
       ON zs."SeriesInstanceUID" = sl."SeriesInstanceUID"
ORDER  BY slice_interval_tolerance  DESC NULLS LAST,
          exposure_range            DESC NULLS LAST,
          series_uid                DESC;