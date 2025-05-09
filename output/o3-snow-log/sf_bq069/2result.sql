/*----------------------------------------------------------
  Report of geometrically-consistent CT image series
  (non-NLST, non-localizer, non-JPEG compressed)
-----------------------------------------------------------*/
WITH prep AS (      /* one row per SOP instance */
    SELECT
        da."SeriesInstanceUID",
        da."SeriesNumber",
        da."StudyInstanceUID",
        da."PatientID",
        da."Rows",
        da."Columns",
        da."SOPInstanceUID",
        da."SliceThickness",
        da."instance_size",
        da."Exposure",
        /* strings for equality checks */
        TO_VARCHAR(da."PixelSpacing")              AS pixel_spacing_str,
        TO_VARCHAR(da."ImageOrientationPatient")   AS img_orient_str,
        TO_VARCHAR(da."ImagePositionPatient")      AS pos_str,
        CONCAT(
            TO_VARCHAR(da."ImagePositionPatient"[0]),
            ',',
            TO_VARCHAR(da."ImagePositionPatient"[1])
        )                                          AS xy_concat,
        /* numeric z-coordinate of position */
        TRY_TO_DOUBLE(da."ImagePositionPatient"[2]::string)           AS z_pos,
        /* |dot product| of orientation cross-Z with [0,0,1] */
        ABS(
              TRY_TO_DOUBLE(da."ImageOrientationPatient"[0]::string)
            * TRY_TO_DOUBLE(da."ImageOrientationPatient"[4]::string)
          - TRY_TO_DOUBLE(da."ImageOrientationPatient"[1]::string)
            * TRY_TO_DOUBLE(da."ImageOrientationPatient"[3]::string)
        )                                          AS cross_z_abs
    FROM  IDC.IDC_V17."DICOM_ALL"   da
    LEFT JOIN  IDC.IDC_V17."DICOM_PIVOT" dp     -- for ImageType (may be NULL)
           ON  da."SOPInstanceUID" = dp."SOPInstanceUID"
    WHERE da."Modality"           =  'CT'
      AND da."collection_name"    <> 'NLST'
      AND da."TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                         '1.2.840.10008.1.2.4.51')
      AND (dp."ImageType" IS NULL OR dp."ImageType" NOT ILIKE '%LOCALIZER%')
),

/* differences between consecutive Z positions within each series */
diffs AS (
    SELECT
        "SeriesInstanceUID",
        ABS(z_pos
          - LAG(z_pos) OVER (PARTITION BY "SeriesInstanceUID"
                              ORDER BY z_pos)
        ) AS diff_z
    FROM prep
),

diff_agg AS (
    SELECT
        "SeriesInstanceUID",
        MAX(diff_z)                    AS max_diff_z,
        MIN(diff_z)                    AS min_diff_z,
        MAX(diff_z) - MIN(diff_z)      AS tol_diff_z
    FROM diffs
    WHERE diff_z IS NOT NULL
    GROUP BY "SeriesInstanceUID"
),

series_agg AS (
    SELECT
        "SeriesInstanceUID",
        MAX("SeriesNumber")                        AS SeriesNumber,
        MAX("StudyInstanceUID")                    AS StudyInstanceUID,
        MAX("PatientID")                           AS PatientID,
        COUNT(*)                                   AS num_instances,
        COUNT(DISTINCT img_orient_str)             AS cnt_orient,
        COUNT(DISTINCT pixel_spacing_str)          AS cnt_pix_sp,
        COUNT(DISTINCT "Rows")                     AS cnt_rows,
        COUNT(DISTINCT "Columns")                  AS cnt_cols,
        COUNT(DISTINCT pos_str)                    AS cnt_pos,
        COUNT(DISTINCT xy_concat)                  AS cnt_xy,
        MIN(cross_z_abs)                           AS min_dot,
        MAX(cross_z_abs)                           AS max_dot,
        SUM("instance_size")                       AS total_bytes,
        COUNT(DISTINCT "SliceThickness")           AS cnt_slice_th,
        COUNT(DISTINCT "Exposure")                 AS cnt_exposure,
        MAX(TRY_TO_DOUBLE("Exposure"))             AS max_exposure,
        MIN(TRY_TO_DOUBLE("Exposure"))             AS min_exposure
    FROM prep
    GROUP BY "SeriesInstanceUID"
),

qualified AS (
    SELECT
        sa.*,
        da.max_diff_z,
        da.min_diff_z,
        da.tol_diff_z
    FROM series_agg sa
    JOIN diff_agg da
      ON sa."SeriesInstanceUID" = da."SeriesInstanceUID"
    WHERE sa.cnt_orient    = 1              -- identical orientation
      AND sa.cnt_pix_sp    = 1              -- identical pixel spacing
      AND sa.cnt_rows      = 1              -- identical rows
      AND sa.cnt_cols      = 1              -- identical columns
      AND sa.num_instances = sa.cnt_pos     -- SOP count = position count
      AND sa.cnt_xy        = 1              -- identical X & Y components
      AND sa.min_dot       >= 0.99          -- near-unity alignment
)

SELECT
    "SeriesInstanceUID"                                 AS "SeriesUID",
    SeriesNumber                                        AS "SeriesNumber",
    StudyInstanceUID                                    AS "StudyUID",
    PatientID                                           AS "PatientID",
    max_dot                                             AS "MaxDotProduct",
    num_instances                                       AS "NumSOPInstances",
    cnt_slice_th                                        AS "DistinctSliceThicknessValues",
    max_diff_z                                          AS "MaxSliceIntervalDiff",
    min_diff_z                                          AS "MinSliceIntervalDiff",
    tol_diff_z                                          AS "SliceIntervalTolerance",
    cnt_exposure                                        AS "DistinctExposureValues",
    max_exposure                                        AS "MaxExposure",
    min_exposure                                        AS "MinExposure",
    (max_exposure - min_exposure)                       AS "ExposureRange",
    (total_bytes / 1024.0 / 1024.0)                     AS "SeriesSizeMiB"
FROM qualified
ORDER BY
    "SliceIntervalTolerance" DESC NULLS LAST,
    "ExposureRange"          DESC NULLS LAST,
    "SeriesUID"              DESC NULLS LAST;