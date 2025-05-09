WITH base AS (
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID",
        "instance_size",
        "ImageOrientationPatient",
        "ImagePositionPatient",
        "Rows",
        "Columns",
        "PixelSpacing",
        "ExposureTime"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND "collection_id" <> 'nlst'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                      '1.2.840.10008.1.2.4.51')
      AND ( "ImageType" IS NULL OR "ImageType"::STRING NOT ILIKE '%LOCALIZER%' )
), decoded AS (
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID",
        "instance_size",
        "Rows",
        "Columns",
        "PixelSpacing",
        "ExposureTime",

        /* row / column direction‑cosines */
        TRY_TO_DOUBLE(("ImageOrientationPatient"[0])::STRING) AS row_x,
        TRY_TO_DOUBLE(("ImageOrientationPatient"[1])::STRING) AS row_y,
        TRY_TO_DOUBLE(("ImageOrientationPatient"[2])::STRING) AS row_z,
        TRY_TO_DOUBLE(("ImageOrientationPatient"[3])::STRING) AS col_x,
        TRY_TO_DOUBLE(("ImageOrientationPatient"[4])::STRING) AS col_y,
        TRY_TO_DOUBLE(("ImageOrientationPatient"[5])::STRING) AS col_z,

        /* slice position (x,y,z) */
        TRY_TO_DOUBLE(("ImagePositionPatient"[0])::STRING)    AS pos_x,
        TRY_TO_DOUBLE(("ImagePositionPatient"[1])::STRING)    AS pos_y,
        TRY_TO_DOUBLE(("ImagePositionPatient"[2])::STRING)    AS pos_z,

        "ImageOrientationPatient"                             AS orient_var
    FROM base
), with_deltas AS (
    SELECT
        d.*,
        /* z‑component of row × column cross‑product */
        (row_x*col_y - row_y*col_x)                       AS cross_z,

        /* inter‑slice spacing */
        pos_z - LAG(pos_z) OVER (PARTITION BY "SeriesInstanceUID"
                                 ORDER BY pos_z)          AS dz
    FROM decoded d
), series_stats AS (
    SELECT
        "SeriesInstanceUID",
        MAX("SeriesNumber") AS "SeriesNumber",
        MAX("PatientID")    AS "PatientID",
        SUM("instance_size")/1048576.0                    AS series_size_MiB,

        COUNT(*)                                          AS n_images,
        COUNT(DISTINCT pos_z)                             AS n_unique_z,
        COUNT(DISTINCT dz)                                AS n_unique_dz,
        COUNT(DISTINCT "ExposureTime")                    AS n_exptime,
        COUNT(DISTINCT orient_var)                        AS n_orient,
        COUNT(DISTINCT TO_VARCHAR("Rows")||'x'||TO_VARCHAR("Columns")) AS n_dim,
        COUNT(DISTINCT "PixelSpacing"::STRING)            AS n_pixsp,
        COUNT(DISTINCT TO_VARCHAR(pos_x)||','||TO_VARCHAR(pos_y))      AS n_xy,
        MAX(ABS(cross_z))                                 AS abs_cross_z
    FROM with_deltas
    GROUP BY "SeriesInstanceUID"
)
SELECT
    "SeriesInstanceUID",
    "SeriesNumber",
    "PatientID",
    ROUND(series_size_MiB,4) AS "SERIES_SIZE_MIB"
FROM series_stats
WHERE n_images    = n_unique_z
  AND n_unique_dz = 1
  AND n_exptime   = 1
  AND n_orient    = 1
  AND n_dim       = 1
  AND n_pixsp     = 1
  AND n_xy        = 1
  AND abs_cross_z BETWEEN 0.99 AND 1.01
ORDER BY "SERIES_SIZE_MIB" DESC NULLS LAST,
         "SeriesInstanceUID"
LIMIT 5;