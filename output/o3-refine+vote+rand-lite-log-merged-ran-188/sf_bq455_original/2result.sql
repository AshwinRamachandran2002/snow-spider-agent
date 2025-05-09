WITH filtered AS (   -- 1) basic per–instance filtering
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID",
        "ImageOrientationPatient",
        "ImagePositionPatient",
        "PixelSpacing",
        "Rows",
        "Columns",
        "ExposureInmAs",
        "instance_size"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND LOWER("collection_id") <> 'nlst'                                   -- not NLST
      AND "TransferSyntaxUID" NOT IN (                                       -- no JPEG‑lossy
              '1.2.840.10008.1.2.4.70',
              '1.2.840.10008.1.2.4.51')
      AND ( "ImageType" IS NULL OR "ImageType" NOT ILIKE '%LOCALIZER%' )     -- no localizers
),
series_stats AS (     -- 2) aggregate per series
    SELECT
        "SeriesInstanceUID",
        ANY_VALUE("PatientID")                     AS "PatientID",
        ANY_VALUE("SeriesNumber")                  AS "SeriesNumber",
        COUNT(*)                                   AS n_images,
        COUNT(DISTINCT "ImageOrientationPatient")  AS n_orients,
        COUNT(DISTINCT "PixelSpacing")             AS n_pixsp,
        COUNT(DISTINCT "Rows")                     AS n_rows,
        COUNT(DISTINCT "Columns")                  AS n_cols,
        COUNT(DISTINCT CAST("ImagePositionPatient"[2] AS FLOAT))             AS n_z,
        COUNT(DISTINCT OBJECT_CONSTRUCT(           -- unique (x,y) positions
                    'x', "ImagePositionPatient"[0],
                    'y', "ImagePositionPatient"[1]))                        AS n_xy,
        COUNT(DISTINCT "ExposureInmAs")            AS n_exposures,
        SUM("instance_size")                       AS bytes_tot,
        ANY_VALUE("ImageOrientationPatient")       AS ori_samp              -- sample orientation
    FROM filtered
    GROUP BY "SeriesInstanceUID"
),
validated AS (       -- 3) keep only series passing all consistency tests
    SELECT *
    FROM series_stats
    WHERE n_orients      = 1      -- single orientation
      AND n_pixsp        = 1      -- single pixel spacing
      AND n_rows         = 1      -- constant rows
      AND n_cols         = 1      -- constant columns
      AND n_images       = n_z    -- no duplicate z‑positions
      AND n_xy           = n_z    -- unique (x,y) per slice
      AND n_exposures   <= 1      -- constant exposure
),
final_ct AS (        -- 4) add orientation/plane check
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID",
        bytes_tot/1048576.0                               AS size_mib,
        ABS( CAST(ori_samp[0] AS FLOAT) * CAST(ori_samp[4] AS FLOAT)
            - CAST(ori_samp[1] AS FLOAT) * CAST(ori_samp[3] AS FLOAT) )     AS z_cross
    FROM validated
)
SELECT
    "SeriesInstanceUID",
    "SeriesNumber",
    "PatientID",
    ROUND(size_mib,2)         AS "SeriesSize_MiB"
FROM final_ct
WHERE z_cross BETWEEN 0.99 AND 1.01                -- axial (or coronal/sagittal) plane check
ORDER BY size_mib DESC NULLS LAST
LIMIT 5;