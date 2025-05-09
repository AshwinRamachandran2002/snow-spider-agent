/* ---------------------------------------------------------------
   CT series quality‑controlled report  (variant‑safe casting)
-----------------------------------------------------------------*/
WITH base AS (   -- instance‑level pre‑filter
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "StudyInstanceUID",
        "PatientID",
        "Rows",
        "Columns",
        TRY_TO_DOUBLE("SliceThickness"::STRING)                AS slice_thickness,
        TRY_TO_DOUBLE("Exposure"::STRING)                      AS exposure_value,
        "TransferSyntaxUID",
        "collection_name",
        TO_VARCHAR("PixelSpacing")                             AS pixel_spacing_str,
        TO_VARCHAR("ImageOrientationPatient")                  AS orientation_str,
        "ImageOrientationPatient",
        "ImagePositionPatient",
        TO_VARCHAR("ImagePositionPatient")                     AS position_str,
        TRY_TO_DOUBLE(("ImagePositionPatient"[2])::STRING)     AS z_pos,
        /* concatenate first two components of Image Position (Patient) */
        TO_VARCHAR("ImagePositionPatient"[0])||','||
        TO_VARCHAR("ImagePositionPatient"[1])                  AS pos_xy_str,
        "instance_size"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND "collection_name" <> 'NLST'
      AND "TransferSyntaxUID" NOT IN
            ('1.2.840.10008.1.2.4.70',            -- JPEG Lossless
             '1.2.840.10008.1.2.4.51')            -- JPEG Baseline
      AND UPPER(TO_VARCHAR("ImageType")) NOT LIKE '%LOCALIZER%'  -- skip localizers
),
dotprod AS (      -- |dot( row×col , [0,0,1] )|
    SELECT
        b.*,
        ABS(
              TRY_TO_DOUBLE((b."ImageOrientationPatient"[0])::STRING)
            * TRY_TO_DOUBLE((b."ImageOrientationPatient"[4])::STRING)
          - TRY_TO_DOUBLE((b."ImageOrientationPatient"[1])::STRING)
            * TRY_TO_DOUBLE((b."ImageOrientationPatient"[3])::STRING)
        )                                                   AS dot_abs
    FROM base b
),
-- slice‑to‑slice Z‑spacing
slice_diffs AS (
    SELECT
        "SeriesInstanceUID",
        ABS(z_pos - LAG(z_pos) OVER (PARTITION BY "SeriesInstanceUID"
                                     ORDER BY z_pos))        AS z_diff
    FROM dotprod
),
slice_agg AS (
    SELECT
        "SeriesInstanceUID",
        MIN(z_diff)  AS min_slice_interval_diff,
        MAX(z_diff)  AS max_slice_interval_diff
    FROM slice_diffs
    WHERE z_diff IS NOT NULL
    GROUP BY "SeriesInstanceUID"
),
series_agg AS (   -- per‑series aggregation
    SELECT
        d."SeriesInstanceUID",
        MAX(d."SeriesNumber")              AS SeriesNumber,
        MAX(d."StudyInstanceUID")          AS StudyInstanceUID,
        MAX(d."PatientID")                 AS PatientID,
        MAX(dot_abs)                       AS max_dot_product,
        COUNT(*)                           AS num_instances,
        COUNT(DISTINCT orientation_str)    AS distinct_orientations,
        COUNT(DISTINCT pixel_spacing_str)  AS distinct_pixel_spacings,
        COUNT(DISTINCT position_str)       AS distinct_positions,
        COUNT(DISTINCT pos_xy_str)         AS distinct_xy_pos,
        COUNT(DISTINCT d."Rows")           AS distinct_rows,
        COUNT(DISTINCT d."Columns")        AS distinct_cols,
        COUNT(DISTINCT slice_thickness)    AS num_slice_thickness_values,
        COUNT(DISTINCT exposure_value)     AS num_exposure_values,
        MAX(exposure_value)                AS max_exposure,
        MIN(exposure_value)                AS min_exposure,
        MAX(exposure_value) - MIN(exposure_value)            AS exposure_range,
        SUM("instance_size")/1048576.0     AS series_size_mib   -- bytes → MiB
    FROM dotprod d
    GROUP BY d."SeriesInstanceUID"
),
qualified AS (    -- apply quality filters
    SELECT
        s.*,
        a.min_slice_interval_diff,
        a.max_slice_interval_diff,
        (a.max_slice_interval_diff - a.min_slice_interval_diff) AS slice_interval_tolerance
    FROM series_agg s
    JOIN slice_agg a
      ON s."SeriesInstanceUID" = a."SeriesInstanceUID"
    WHERE s.distinct_orientations   = 1
      AND s.distinct_pixel_spacings = 1
      AND s.num_instances           = s.distinct_positions
      AND s.distinct_xy_pos         = 1
      AND s.distinct_rows           = 1
      AND s.distinct_cols           = 1
      AND s.max_dot_product BETWEEN 0.99 AND 1.01
)
-- final report ----------------------------------------------------
SELECT
    "SeriesInstanceUID"                                         AS series_uid,
    SeriesNumber,
    StudyInstanceUID,
    PatientID,
    ROUND(max_dot_product, 6)                                   AS max_dot_product,
    num_instances,
    num_slice_thickness_values,
    max_slice_interval_diff,
    min_slice_interval_diff,
    slice_interval_tolerance,
    num_exposure_values,
    max_exposure,
    min_exposure,
    exposure_range,
    ROUND(series_size_mib, 2)                                   AS series_size_mib
FROM qualified
ORDER BY
    slice_interval_tolerance DESC NULLS LAST,
    exposure_range           DESC NULLS LAST,
    "SeriesInstanceUID"      DESC;