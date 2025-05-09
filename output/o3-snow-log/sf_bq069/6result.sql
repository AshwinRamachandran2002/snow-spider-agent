/*-----------------------------------------------------------
Corrected version: casts the ARRAY/VARIANT elements to STRING
before TRY_TO_DOUBLE to avoid the variant→float compilation
error reported by Snowflake.
-----------------------------------------------------------*/
WITH instance_filtered AS (
    /* 1. keep CT, exclude NLST, JPEG-compressed & localizers */
    SELECT
        da."SeriesInstanceUID",
        da."SeriesNumber",
        da."StudyInstanceUID",
        da."PatientID",
        da."SliceThickness",
        da."Exposure",
        da."Rows",
        da."Columns",
        da."PixelSpacing",
        da."ImageOrientationPatient",
        da."ImagePositionPatient",
        da."SOPInstanceUID",
        da."instance_size",

        /* Image Position (Patient) components ----------------*/
        TRY_TO_DOUBLE( (da."ImagePositionPatient"[0])::STRING )  AS x_pos,
        TRY_TO_DOUBLE( (da."ImagePositionPatient"[1])::STRING )  AS y_pos,
        TRY_TO_DOUBLE( (da."ImagePositionPatient"[2])::STRING )  AS z_pos,

        /* Image Orientation (Patient) components -------------*/
        TRY_TO_DOUBLE( (da."ImageOrientationPatient"[0])::STRING ) AS r_x,
        TRY_TO_DOUBLE( (da."ImageOrientationPatient"[1])::STRING ) AS r_y,
        TRY_TO_DOUBLE( (da."ImageOrientationPatient"[2])::STRING ) AS r_z,
        TRY_TO_DOUBLE( (da."ImageOrientationPatient"[3])::STRING ) AS c_x,
        TRY_TO_DOUBLE( (da."ImageOrientationPatient"[4])::STRING ) AS c_y,
        TRY_TO_DOUBLE( (da."ImageOrientationPatient"[5])::STRING ) AS c_z,

        /* |(row × col) · [0 0 1]| ---------------------------*/
        ABS(
              TRY_TO_DOUBLE( (da."ImageOrientationPatient"[0])::STRING )   -- r_x
            * TRY_TO_DOUBLE( (da."ImageOrientationPatient"[4])::STRING )   -- c_y
            - TRY_TO_DOUBLE( (da."ImageOrientationPatient"[1])::STRING )   -- r_y
            * TRY_TO_DOUBLE( (da."ImageOrientationPatient"[3])::STRING )   -- c_x
        )                                                                AS dot_cross_z
    FROM IDC.IDC_V17."DICOM_ALL"  da
    LEFT JOIN IDC.IDC_V17."DICOM_PIVOT" dp
           ON da."SOPInstanceUID" = dp."SOPInstanceUID"
    WHERE da."Modality" = 'CT'
      AND UPPER(da."collection_name") <> 'NLST'
      AND da."TransferSyntaxUID" NOT IN
          ('1.2.840.10008.1.2.4.70',   /* JPEG Lossless */
           '1.2.840.10008.1.2.4.51')   /* JPEG Baseline */
      AND (dp."ImageType" IS NULL OR dp."ImageType" NOT ILIKE '%LOCALIZER%')
),

inst_with_spacing AS (
    /* 2. compute inter-slice spacing & numeric exposure ------*/
    SELECT
        f.*,
        ABS( LEAD(z_pos) OVER (PARTITION BY f."SeriesInstanceUID"
                               ORDER BY z_pos)
             - z_pos )                             AS z_spacing,
        TRY_TO_DOUBLE(f."Exposure")                AS exposure_val
    FROM instance_filtered f
)

SELECT
    /* ------------ identifiers ------------------------------*/
    "SeriesInstanceUID"                                  AS "SeriesUID",
    MAX("SeriesNumber")                                  AS "SeriesNumber",
    MAX("StudyInstanceUID")                              AS "StudyUID",
    MAX("PatientID")                                     AS "PatientID",

    /* ------------ geometry quality ------------------------*/
    MAX(dot_cross_z)                                     AS "MaxDotProduct",

    /* ------------ basic counts ---------------------------*/
    COUNT(*)                                             AS "SOPInstances",
    COUNT(DISTINCT "SliceThickness")                     AS "DistinctSliceThickness",

    /* ------------ z-spacing stats ------------------------*/
    MAX(z_spacing)                                       AS "MaxSliceIntvlDiff",
    MIN(z_spacing)                                       AS "MinSliceIntvlDiff",
    MAX(z_spacing) - MIN(z_spacing)                      AS "SliceDiffTolerance",

    /* ------------ exposure stats -------------------------*/
    COUNT(DISTINCT exposure_val)                         AS "DistinctExposureValues",
    MAX(exposure_val)                                    AS "MaxExposure",
    MIN(exposure_val)                                    AS "MinExposure",
    MAX(exposure_val) - MIN(exposure_val)                AS "ExposureRange",

    /* ------------ total series size ----------------------*/
    SUM("instance_size") / 1048576.0                     AS "SeriesSize_MiB"

FROM inst_with_spacing
GROUP BY "SeriesInstanceUID"

HAVING
      /* identical orientation & pixel spacing -------------*/
      COUNT(DISTINCT TO_VARCHAR("ImageOrientationPatient")) = 1
  AND COUNT(DISTINCT TO_VARCHAR("PixelSpacing"))           = 1

      /* dot-product within 1 ± 0.01 -----------------------*/
  AND MIN(dot_cross_z) >= 0.99
  AND MAX(dot_cross_z) <= 1.01

      /* instance ↔ position one-to-one --------------------*/
  AND COUNT(DISTINCT TO_VARCHAR("ImagePositionPatient")) = COUNT(*)

      /* identical first two position components -----------*/
  AND COUNT(DISTINCT x_pos) = 1
  AND COUNT(DISTINCT y_pos) = 1

      /* uniform rows & columns ----------------------------*/
  AND COUNT(DISTINCT "Rows")    = 1
  AND COUNT(DISTINCT "Columns") = 1

ORDER BY
    "SliceDiffTolerance" DESC NULLS LAST,
    "ExposureRange"      DESC NULLS LAST,
    "SeriesUID"          DESC NULLS LAST;