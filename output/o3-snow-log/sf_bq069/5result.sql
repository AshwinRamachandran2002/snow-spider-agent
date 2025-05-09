WITH base AS (             ---------------------------------------------------- 1
    SELECT
        "SeriesInstanceUID",
        "SOPInstanceUID",
        "PatientID",
        "StudyInstanceUID",
        "SeriesNumber",
        "SliceThickness",
        TRY_TO_DOUBLE("Exposure")                       AS exposure_val,
        "instance_size",
        "Rows",
        "Columns",
        "TransferSyntaxUID",
        "ImageOrientationPatient"                       AS orient,
        "ImagePositionPatient"                          AS pos,
        "PixelSpacing",
        /* helper strings for equality tests */
        TO_VARCHAR("ImageOrientationPatient")           AS orientation_str,
        TO_VARCHAR("PixelSpacing")                      AS pixel_spacing_str,
        TO_VARCHAR("ImagePositionPatient")              AS pos_str,
        CONCAT(pos[0]::STRING, '|', pos[1]::STRING)     AS first_two_pos,
        /* z-coordinate and orientation maths */
        CAST(pos[2]                       AS DOUBLE)    AS z_pos,
        CAST(orient[0]                   AS DOUBLE)     AS rx,
        CAST(orient[1]                   AS DOUBLE)     AS ry,
        CAST(orient[3]                   AS DOUBLE)     AS cx,
        CAST(orient[4]                   AS DOUBLE)     AS cy,
        ( CAST(orient[0] AS DOUBLE) * CAST(orient[4] AS DOUBLE)
        - CAST(orient[1] AS DOUBLE) * CAST(orient[3] AS DOUBLE) ) AS normal_z
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND "collection_name" <> 'NLST'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                      '1.2.840.10008.1.2.4.51')
),                          ---------------------------------------------------- 2
series_stats AS (
    SELECT
        "SeriesInstanceUID",
        MAX("SeriesNumber")                                   AS series_number,
        MAX("StudyInstanceUID")                               AS study_uid,
        MAX("PatientID")                                      AS patient_id,
        COUNT(DISTINCT "SOPInstanceUID")                      AS total_sops,
        COUNT(DISTINCT pos_str)                               AS distinct_pos,
        COUNT(DISTINCT orientation_str)                       AS distinct_orientation,
        COUNT(DISTINCT pixel_spacing_str)                     AS distinct_pixel_spacing,
        COUNT(DISTINCT first_two_pos)                         AS distinct_first_two_pos,
        COUNT(DISTINCT "Rows")                                AS distinct_rows,
        COUNT(DISTINCT "Columns")                             AS distinct_cols,
        COUNT(DISTINCT "SliceThickness")                      AS distinct_slice_thickness,
        SUM("instance_size")                                  AS total_size_bytes,
        MAX(ABS(normal_z))                                    AS max_abs_dot,
        MIN(ABS(normal_z))                                    AS min_abs_dot,
        MAX(exposure_val)                                     AS max_exposure,
        MIN(exposure_val)                                     AS min_exposure,
        COUNT(DISTINCT exposure_val)                          AS distinct_exposure
    FROM base
    GROUP BY "SeriesInstanceUID"
),                          ---------------------------------------------------- 3
deltas AS (
    SELECT
        "SeriesInstanceUID",
        z_pos,
        ROW_NUMBER() OVER (PARTITION BY "SeriesInstanceUID" ORDER BY z_pos) AS rn
    FROM base
    WHERE z_pos IS NOT NULL
),                          ---------------------------------------------------- 4
delta_calc AS (
    SELECT
        d1."SeriesInstanceUID",
        ABS(d1.z_pos - d0.z_pos) AS delta_z
    FROM deltas d1
    JOIN deltas d0
      ON d1."SeriesInstanceUID" = d0."SeriesInstanceUID"
     AND d1.rn                = d0.rn + 1
),                          ---------------------------------------------------- 5
slice_delta_stats AS (
    SELECT
        "SeriesInstanceUID",
        MAX(delta_z) AS max_delta_z,
        MIN(delta_z) AS min_delta_z
    FROM delta_calc
    GROUP BY "SeriesInstanceUID"
),                          ---------------------------------------------------- 6
localizer_series AS (
    SELECT DISTINCT "SeriesInstanceUID"
    FROM IDC.IDC_V17.DICOM_PIVOT
    WHERE UPPER("ImageType") LIKE '%LOCALIZER%'
)                           ---------------------------------------------------- 7
SELECT
    ss."SeriesInstanceUID"                                       AS series_uid,          -- 1
    ss.series_number                                             AS series_number,       -- 2
    ss.study_uid                                                 AS study_uid,           -- 3
    ss.patient_id                                                AS patient_id,          -- 4
    ROUND(ss.max_abs_dot, 6)                                     AS max_dot_product,     -- 5
    ss.total_sops                                                AS sop_count,           -- 6
    ss.distinct_slice_thickness                                  AS slice_thickness_vals,-- 7
    sds.max_delta_z                                              AS max_slice_gap,       -- 8 (max)
    sds.min_delta_z                                              AS min_slice_gap,       -- 8 (min)
    (sds.max_delta_z - sds.min_delta_z)                          AS slice_gap_tolerance, -- 9
    ss.distinct_exposure                                         AS exposure_val_count,  -- 10
    ss.max_exposure                                              AS max_exposure,        -- 11 (max)
    ss.min_exposure                                              AS min_exposure,        -- 11 (min)
    (ss.max_exposure - ss.min_exposure)                          AS exposure_range,      -- 12
    ROUND(ss.total_size_bytes/1048576, 4)                        AS series_size_mib      -- 13
FROM   series_stats       ss
JOIN   slice_delta_stats  sds  ON ss."SeriesInstanceUID" = sds."SeriesInstanceUID"
WHERE  ss.distinct_orientation      = 1            -- single orientation
  AND  ss.distinct_pixel_spacing    = 1            -- identical pixel spacing
  AND  ss.total_sops               = ss.distinct_pos        -- SOP = position count
  AND  ss.distinct_first_two_pos    = 1            -- identical first 2 position comps
  AND  ss.distinct_rows             = 1            -- identical rows
  AND  ss.distinct_cols             = 1            -- identical cols
  AND  ss.min_abs_dot              >= 0.99         -- axial ±0.01
  AND  ss."SeriesInstanceUID" NOT IN (SELECT "SeriesInstanceUID" FROM localizer_series)
ORDER BY
    slice_gap_tolerance    DESC NULLS LAST,
    exposure_range         DESC NULLS LAST,
    series_uid             DESC NULLS LAST;