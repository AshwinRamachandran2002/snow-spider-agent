WITH per_image AS (   -- gather per–image data that pass all basic filters
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID",
        "ImageOrientationPatient",
        "PixelSpacing",
        "Rows",
        "Columns",
        /* z-coordinate of the image position */
        ("ImagePositionPatient"[2]::FLOAT)                                         AS z_pos,
        /* | z-component of cross-product of orientation row & column vectors | */
        ABS( ("ImageOrientationPatient"[0]::FLOAT * "ImageOrientationPatient"[4]::FLOAT)
           - ("ImageOrientationPatient"[1]::FLOAT * "ImageOrientationPatient"[3]::FLOAT) ) 
                                                                                  AS abs_cross_z,
        "instance_size"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'                                              -- CT only
      AND "collection_id" <> 'nlst'                                      -- exclude NLST
      AND ( "TransferSyntaxUID" NOT IN ( '1.2.840.10008.1.2.4.70',       -- exclude JPEG
                                         '1.2.840.10008.1.2.4.51')
            OR "TransferSyntaxUID" IS NULL )
      AND UPPER("ImageType"::STRING) NOT ILIKE '%LOCALIZER%'             -- exclude localizers
      AND "ImageOrientationPatient" IS NOT NULL
      AND "ImagePositionPatient"   IS NOT NULL
), per_series AS (  -- consolidate per-series QA metrics
    SELECT
        "SeriesInstanceUID",
        MIN("SeriesNumber")                             AS "SeriesNumber",
        MIN("PatientID")                                AS "PatientID",
        COUNT(*)                                        AS n_images,
        COUNT(DISTINCT z_pos)                           AS n_z,
        COUNT(DISTINCT "ImageOrientationPatient")       AS orient_cnt,
        COUNT(DISTINCT "PixelSpacing")                  AS pixspace_cnt,
        COUNT(DISTINCT "Rows")                          AS row_cnt,
        COUNT(DISTINCT "Columns")                       AS col_cnt,
        MIN(abs_cross_z)                                AS min_abs_cross_z,
        MAX(abs_cross_z)                                AS max_abs_cross_z,
        ROUND(SUM("instance_size")/1048576,2)           AS series_size_MiB
    FROM per_image
    GROUP BY "SeriesInstanceUID"
)
SELECT
    "SeriesInstanceUID",
    "SeriesNumber",
    "PatientID",
    series_size_MiB
FROM per_series
WHERE n_images      = n_z          -- no duplicate z positions
  AND orient_cnt    = 1            -- single orientation
  AND pixspace_cnt  = 1            -- single pixel spacing
  AND row_cnt       = 1            -- consistent rows
  AND col_cnt       = 1            -- consistent columns
  AND min_abs_cross_z BETWEEN 0.99 AND 1.01  -- axial plane check
  AND max_abs_cross_z BETWEEN 0.99 AND 1.01
ORDER BY series_size_MiB DESC NULLS LAST
LIMIT 5;