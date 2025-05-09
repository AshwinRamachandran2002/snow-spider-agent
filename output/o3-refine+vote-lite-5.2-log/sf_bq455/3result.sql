WITH images_filtered AS (
    SELECT
        "SeriesInstanceUID",
        "PatientID",
        "SeriesNumber",
        "PixelSpacing",
        "ImageOrientationPatient",
        "Rows",
        "Columns",
        /* round to remove tiny numerical noise before DISTINCT tests */
        ROUND(("ImagePositionPatient"[0])::FLOAT,5) AS x_pos,
        ROUND(("ImagePositionPatient"[1])::FLOAT,5) AS y_pos,
        ROUND(("ImagePositionPatient"[2])::FLOAT,5) AS z_pos,
        "ExposureInmAs",
        "instance_size"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE
          "Modality" = 'CT'
      AND LOWER("collection_id") <> 'nlst'                        -- exclude NLST
      AND ( "ImageType" IS NULL OR NOT UPPER("ImageType") LIKE '%LOCALIZER%' )
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',   -- exclude JPEG‐lossy
                                      '1.2.840.10008.1.2.4.51')
),
deltas AS (
    /* compute slice‑to‑slice spacing within each series */
    SELECT
        f.*,
        ABS( z_pos
             - LAG(z_pos) OVER (PARTITION BY "SeriesInstanceUID" ORDER BY z_pos)
           ) AS slice_spacing
    FROM images_filtered f
),
series_agg AS (
    SELECT
        "SeriesInstanceUID",
        MIN("PatientID")                             AS patient_id,
        MIN("SeriesNumber")                          AS series_number,
        SUM("instance_size")/1024.0/1024.0           AS series_size_mib,
        COUNT(*)                                     AS n_images,
        COUNT(DISTINCT z_pos)                        AS n_unique_z,
        COUNT(DISTINCT x_pos)                        AS n_unique_x,
        COUNT(DISTINCT y_pos)                        AS n_unique_y,
        COUNT(DISTINCT "PixelSpacing"::STRING)       AS n_unique_pixsp,
        COUNT(DISTINCT "ImageOrientationPatient"::STRING) AS n_unique_orient,
        COUNT(DISTINCT "Rows")                       AS n_unique_rows,
        COUNT(DISTINCT "Columns")                    AS n_unique_cols,
        COUNT(DISTINCT "ExposureInmAs")              AS n_unique_exposure,
        COUNT(DISTINCT ROUND(slice_spacing,4))       AS n_unique_spacing,
        /* |cz| from cross product of X & Y direction cosines */
        ABS(
            MIN(("ImageOrientationPatient"[0])::FLOAT) * MIN(("ImageOrientationPatient"[4])::FLOAT) -
            MIN(("ImageOrientationPatient"[1])::FLOAT) * MIN(("ImageOrientationPatient"[3])::FLOAT)
        )                                            AS abs_cz
    FROM deltas
    GROUP BY "SeriesInstanceUID"
),
filtered_series AS (
    SELECT *
    FROM series_agg
    WHERE
          n_images              = n_unique_z        -- no duplicate z positions
      AND n_unique_x            = 1
      AND n_unique_y            = 1
      AND n_unique_pixsp        = 1
      AND n_unique_orient       = 1
      AND n_unique_rows         = 1
      AND n_unique_cols         = 1
      AND n_unique_exposure    <= 1                 -- allow 0 or 1 distinct exposure value
      AND n_unique_spacing      = 1
      AND abs_cz BETWEEN 0.99 AND 1.01              -- axial or coronal alignment
)
SELECT
    "SeriesInstanceUID",
    series_number  AS "SeriesNumber",
    patient_id     AS "PatientID",
    ROUND(series_size_mib,2) AS "SeriesSize_MiB"
FROM filtered_series
ORDER BY series_size_mib DESC NULLS LAST, "SeriesInstanceUID"
LIMIT 5;