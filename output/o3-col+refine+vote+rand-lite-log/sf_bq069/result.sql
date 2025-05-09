/*  ----------------------------------------------------------
    CT series quality-controlled geometry & exposure report
    ---------------------------------------------------------- */
WITH ct_pre AS (   -- 1. keep non-NLST CT instances, skip JPEG-compressed ones
    SELECT  *
    FROM    IDC.IDC_V17.DICOM_ALL
    WHERE   "Modality" = 'CT'
      AND   "collection_name" <> 'NLST'
      AND   "TransferSyntaxUID" NOT IN (
              '1.2.840.10008.1.2.4.70',   -- JPEG-Lossless
              '1.2.840.10008.1.2.4.51'    -- JPEG-Baseline
            )
),
ct_rows AS (       -- 2. derive per-row helper values
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "StudyInstanceUID",
        "PatientID",
        "Rows",
        "Columns",
        "SliceThickness",
        TRY_TO_NUMBER("SliceThickness")               AS slice_thick_f,
        TRY_TO_NUMBER("Exposure")                     AS exposure_f,
        "instance_size",

        /* geometry helpers */
        "PixelSpacing"::STRING                        AS pixspacing_str,
        "ImageOrientationPatient"::STRING             AS orient_str,
        ABS(
            (PARSE_JSON("ImageOrientationPatient")[0]::FLOAT *
             PARSE_JSON("ImageOrientationPatient")[4]::FLOAT) -
            (PARSE_JSON("ImageOrientationPatient")[1]::FLOAT *
             PARSE_JSON("ImageOrientationPatient")[3]::FLOAT)
        )                                             AS abs_dot_ref_z,
        PARSE_JSON("ImagePositionPatient")[2]::FLOAT  AS z_pos,
        ARRAY_CONSTRUCT(
              PARSE_JSON("ImagePositionPatient")[0]::STRING,
              PARSE_JSON("ImagePositionPatient")[1]::STRING
        )::STRING                                     AS first_xy_str,

        /* localizer flag */
        CASE
            WHEN "ImageType"::STRING ILIKE '%LOCALIZER%' THEN 1 ELSE 0
        END                                           AS has_localizer_flag
    FROM  ct_pre
),
z_diff AS (        -- 3. compute slice-to-slice spacing per series
    SELECT
        r.*,
        LEAD(z_pos) OVER (PARTITION BY "SeriesInstanceUID" ORDER BY z_pos) AS next_z
    FROM ct_rows r
),
series_aggr AS (   -- 4. aggregate required metrics per series
    SELECT
        "SeriesInstanceUID"                                                  AS series_uid,
        MIN("SeriesNumber")                                                  AS series_number,
        MIN("StudyInstanceUID")                                              AS study_uid,
        MIN("PatientID")                                                     AS patient_id,

        MAX(abs_dot_ref_z)                                                   AS max_dot_product,
        MIN(abs_dot_ref_z)                                                   AS min_dot_product,
        COUNT(*)                                                             AS num_sops,
        COUNT(DISTINCT z_pos::STRING)                                        AS distinct_z_pos,
        COUNT(DISTINCT orient_str)                                           AS distinct_orient,
        COUNT(DISTINCT pixspacing_str)                                       AS distinct_pixspace,
        COUNT(DISTINCT first_xy_str)                                         AS distinct_xy,
        COUNT(DISTINCT "Rows")                                               AS distinct_rows,
        COUNT(DISTINCT "Columns")                                            AS distinct_cols,
        MAX(has_localizer_flag)                                              AS has_localizer,

        COUNT(DISTINCT slice_thick_f)                                        AS distinct_slice_thick,
        MAX(ABS(next_z - z_pos))                                             AS max_slice_interval,
        MIN(ABS(next_z - z_pos))                                             AS min_slice_interval,
        MAX(ABS(next_z - z_pos)) - MIN(ABS(next_z - z_pos))                  AS slice_interval_tolerance,

        COUNT(DISTINCT exposure_f)                                           AS distinct_exposure_vals,
        MAX(exposure_f)                                                      AS max_exposure,
        MIN(exposure_f)                                                      AS min_exposure,
        MAX(exposure_f) - MIN(exposure_f)                                    AS exposure_range,

        SUM("instance_size") / (1024*1024)                                   AS series_size_mib
    FROM z_diff
    GROUP BY "SeriesInstanceUID"
),
series_filtered AS (  -- 5. retain only series that satisfy all QC rules
    SELECT *
    FROM   series_aggr
    WHERE  has_localizer         = 0           -- no localizer images
       AND distinct_orient       = 1           -- single orientation
       AND distinct_pixspace     = 1           -- single pixel spacing
       AND distinct_rows         = 1           -- uniform rows
       AND distinct_cols         = 1           -- uniform columns
       AND distinct_xy           = 1           -- identical x-y ImagePosition
       AND num_sops = distinct_z_pos           -- #instances == #distinct Z
       AND min_dot_product >= 0.99
       AND max_dot_product <= 1.01
)
-- 6. final ordered report
SELECT
    series_uid                   AS "SeriesInstanceUID",
    series_number                AS "SeriesNumber",
    study_uid                    AS "StudyInstanceUID",
    patient_id                   AS "PatientID",
    max_dot_product              AS "MaxDotProduct",
    num_sops                     AS "NumSOPInstances",
    distinct_slice_thick         AS "DistinctSliceThickness",
    max_slice_interval           AS "MaxSliceInterval",
    min_slice_interval           AS "MinSliceInterval",
    slice_interval_tolerance     AS "SliceIntervalTolerance",
    distinct_exposure_vals       AS "DistinctExposureValues",
    max_exposure                 AS "MaxExposure",
    min_exposure                 AS "MinExposure",
    exposure_range               AS "ExposureRange",
    series_size_mib              AS "SeriesSizeMiB"
FROM series_filtered
ORDER BY
    slice_interval_tolerance DESC NULLS LAST,
    exposure_range           DESC NULLS LAST,
    series_uid               DESC NULLS LAST;