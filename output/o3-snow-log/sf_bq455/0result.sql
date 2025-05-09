WITH per_instance AS (          -------------------------------------------------
    /* 1.  keep only CT instances from collections other than NLST          */
    /*     and that are not JPEG-compressed or LOCALIZER images             */
    -------------------------------------------------*/
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID",
        "instance_size",                              -- bytes

        /*  flags & acquisition parameters used later for consistency tests */
        "TransferSyntaxUID",
        UPPER(CAST("ImageType" AS STRING))               AS img_type_str,
        "ImageOrientationPatient"                        AS iop,        -- VARIANT
        "PixelSpacing"                                   AS pixsp,      -- VARIANT
        "Rows"                                           AS img_rows,
        "Columns"                                        AS img_cols,
        "ImagePositionPatient"                           AS ipp,        -- VARIANT
        ("ImagePositionPatient"[2])::FLOAT               AS z_pos,      -- z-coordinate
        ABS(                                             -- | ẑ · ( x̂ × ŷ ) |
              ("ImageOrientationPatient"[0]::FLOAT) * ("ImageOrientationPatient"[4]::FLOAT)
            - ("ImageOrientationPatient"[1]::FLOAT) * ("ImageOrientationPatient"[3]::FLOAT)
        )                                                AS z_cosine_abs,
        "XRayTubeCurrentInmA"                            AS tube_current
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality"                  = 'CT'
      AND "collection_id"            <> 'nlst'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',          -- JPEG LS
                                      '1.2.840.10008.1.2.4.51')          -- JPEG 2000
      AND img_type_str NOT LIKE '%LOCALIZER%'
      AND "ImageOrientationPatient" IS NOT NULL
      AND "ImagePositionPatient"    IS NOT NULL
      AND "PixelSpacing"            IS NOT NULL
),

/* 2.  number of different slice spacings (Δz) per series ------------------*/
slice_diff AS (
    SELECT
        "SeriesInstanceUID",
        COUNT(DISTINCT ROUND(dz,6)) AS n_dz                           -- expect 1
    FROM (
        SELECT
            "SeriesInstanceUID",
            ABS(z_pos - LAG(z_pos) OVER (PARTITION BY "SeriesInstanceUID"
                                         ORDER BY z_pos)) AS dz
        FROM per_instance
    )
    WHERE dz IS NOT NULL
    GROUP BY "SeriesInstanceUID"
),

/* 3.  per-series consistency checks & total size --------------------------*/
series_stats AS (
    SELECT
        "SeriesInstanceUID",
        MAX("SeriesNumber")                                      AS series_number,
        MAX("PatientID")                                         AS patient_id,
        SUM("instance_size") / (1024*1024)                       AS series_size_mib,

        COUNT(*)                           AS n_images,
        COUNT(DISTINCT iop)                AS n_iop,
        COUNT(DISTINCT pixsp)              AS n_pixsp,
        COUNT(DISTINCT img_rows)           AS n_rows,
        COUNT(DISTINCT img_cols)           AS n_cols,
        COUNT(DISTINCT z_pos)              AS n_z,

        /* unique (x,y) slice origins rounded to 6 dp */
        COUNT(DISTINCT CONCAT(
                ROUND(ipp[0]::FLOAT,6), ',', ROUND(ipp[1]::FLOAT,6)
             ))                             AS n_xy,

        MIN(z_cosine_abs)                  AS min_zcos,
        MAX(z_cosine_abs)                  AS max_zcos,
        COUNT(DISTINCT tube_current)       AS n_tube_current
    FROM per_instance
    GROUP BY "SeriesInstanceUID"
)

/* 4.  final selection -----------------------------------------------------*/
SELECT
    ss."SeriesInstanceUID",
    ss.series_number          AS "SeriesNumber",
    ss.patient_id             AS "PatientID",
    ss.series_size_mib        AS "SeriesSize_MiB"
FROM series_stats ss
JOIN slice_diff  sd  ON ss."SeriesInstanceUID" = sd."SeriesInstanceUID"
WHERE ss.n_images        = ss.n_z        -- one image per unique z
  AND sd.n_dz            = 1             -- constant slice spacing
  AND ss.n_iop           = 1             -- single orientation
  AND ss.n_pixsp         = 1             -- constant pixel spacing
  AND ss.n_rows          = 1             -- constant rows
  AND ss.n_cols          = 1             -- constant columns
  AND ss.n_xy            = 1             -- constant in-plane origin
  AND ss.n_tube_current <= 1             -- constant exposure
  AND ss.min_zcos BETWEEN 0.99 AND 1.01  -- axial/aligned series
  AND ss.max_zcos BETWEEN 0.99 AND 1.01
ORDER BY ss.series_size_mib DESC NULLS LAST
LIMIT 5;