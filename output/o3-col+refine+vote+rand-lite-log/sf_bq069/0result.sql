/* ---------------------------------------------------------------
   Report of geometrically-consistent CT series (non-NLST, non-JPEG,
   non-LOCALIZER) that satisfy all required geometry checks.
---------------------------------------------------------------- */
WITH filtered AS (   /* individual-instance level filter */
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "StudyInstanceUID",
        "PatientID",
        "SliceThickness",
        TRY_TO_DOUBLE("Exposure")                             AS exposure_num,
        "Exposure",
        "instance_size",
        "Rows",
        "Columns",
        TO_VARCHAR("PixelSpacing")                            AS pixel_spacing_str,
        TO_VARCHAR("ImageOrientationPatient")                 AS iop_str,
        TO_VARCHAR("ImagePositionPatient")                    AS ipp_str,
        /* numeric components for geometry math */
        TRY_TO_DOUBLE(("ImageOrientationPatient"[0])::STRING) AS row_x,
        TRY_TO_DOUBLE(("ImageOrientationPatient"[1])::STRING) AS row_y,
        TRY_TO_DOUBLE(("ImageOrientationPatient"[3])::STRING) AS col_x,
        TRY_TO_DOUBLE(("ImageOrientationPatient"[4])::STRING) AS col_y,
        TRY_TO_DOUBLE(("ImagePositionPatient"[0])::STRING)    AS pos_x,
        TRY_TO_DOUBLE(("ImagePositionPatient"[1])::STRING)    AS pos_y,
        TRY_TO_DOUBLE(("ImagePositionPatient"[2])::STRING)    AS pos_z
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality"           = 'CT'
      AND "collection_name"   <> 'NLST'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',   -- JPEG Lossless
                                      '1.2.840.10008.1.2.4.51')   -- JPEG Baseline
      AND "ImageType" NOT ILIKE '%LOCALIZER%'
),
with_dot AS (   /* dot product of orientation-normal vs Z-axis */
    SELECT
        f.*,
        ABS(row_x * col_y - row_y * col_x) AS abs_dot
    FROM filtered f
),
dz_values AS (  /* slice-to-slice spacing per series */
    SELECT
        "SeriesInstanceUID",
        ABS(pos_z - LAG(pos_z) OVER (PARTITION BY "SeriesInstanceUID"
                                     ORDER BY pos_z)) AS dz
    FROM with_dot
),
slice_stats AS (
    SELECT
        "SeriesInstanceUID",
        MAX(dz) AS max_dz,
        MIN(dz) AS min_dz
    FROM dz_values
    WHERE dz IS NOT NULL
    GROUP BY "SeriesInstanceUID"
),
series_aggr AS ( /* series-level aggregation + consistency counts */
    SELECT
        "SeriesInstanceUID",
        MIN("SeriesNumber")                        AS series_number,
        MIN("StudyInstanceUID")                    AS study_uid,
        MIN("PatientID")                           AS patient_id,
        MAX(abs_dot)                               AS max_abs_dot,
        COUNT(*)                                   AS total_instances,
        COUNT(DISTINCT "SliceThickness")           AS distinct_slice_thickness,
        COUNT(DISTINCT iop_str)                    AS orientation_variants,
        COUNT(DISTINCT pixel_spacing_str)          AS pixel_spacing_variants,
        COUNT(DISTINCT ipp_str)                    AS unique_positions,
        COUNT(DISTINCT TO_VARCHAR(pos_x)||','||
                         TO_VARCHAR(pos_y))        AS first2pos_variants,
        COUNT(DISTINCT "Rows")                     AS row_variants,
        COUNT(DISTINCT "Columns")                  AS col_variants,
        SUM("instance_size")                       AS total_size_bytes,
        COUNT(DISTINCT "Exposure")                 AS distinct_exposures,
        MIN(exposure_num)                          AS min_exposure,
        MAX(exposure_num)                          AS max_exposure
    FROM with_dot
    GROUP BY "SeriesInstanceUID"
),
qualified AS (  /* enforce all geometry / consistency rules */
    SELECT
        q.*,
        s.max_dz,
        s.min_dz
    FROM series_aggr q
    LEFT JOIN slice_stats s
           ON q."SeriesInstanceUID" = s."SeriesInstanceUID"
    WHERE orientation_variants   = 1
      AND pixel_spacing_variants = 1
      AND row_variants           = 1
      AND col_variants           = 1
      AND total_instances        = unique_positions
      AND first2pos_variants     = 1
      AND max_abs_dot           >= 0.99      -- 1 ± 0.01
)
SELECT
    "SeriesInstanceUID",
    series_number                                   AS "SeriesNumber",
    study_uid                                       AS "StudyInstanceUID",
    patient_id                                      AS "PatientID",
    ROUND(max_abs_dot, 5)                           AS "MaxDotProduct",
    total_instances                                 AS "NumSOPInstances",
    distinct_slice_thickness                        AS "DistinctSliceThicknessValues",
    max_dz                                          AS "MaxSliceSpacing",
    min_dz                                          AS "MinSliceSpacing",
    (max_dz - min_dz)                               AS "SliceSpacingTolerance",
    distinct_exposures                              AS "DistinctExposureValues",
    max_exposure                                    AS "MaxExposure",
    min_exposure                                    AS "MinExposure",
    (max_exposure - min_exposure)                   AS "ExposureRange",
    ROUND(total_size_bytes / 1048576, 3)            AS "SeriesSize_MiB"
FROM qualified
ORDER BY
    "SliceSpacingTolerance" DESC NULLS LAST,
    "ExposureRange"         DESC NULLS LAST,
    "SeriesInstanceUID"     DESC NULLS LAST;