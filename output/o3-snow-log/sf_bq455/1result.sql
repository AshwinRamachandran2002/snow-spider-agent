WITH series_stats AS (
    SELECT
        "SeriesInstanceUID",
        ANY_VALUE("SeriesNumber")          AS "SeriesNumber",
        ANY_VALUE("PatientID")             AS "PatientID",
        SUM("instance_size")               AS total_bytes,
        COUNT(*)                           AS num_images,

        /* consistency counts */
        COUNT(DISTINCT TO_JSON("ImageOrientationPatient"))                          AS orient_cnt,
        COUNT(DISTINCT TO_JSON("PixelSpacing"))                                      AS pxspace_cnt,
        COUNT(DISTINCT "Rows")                                                      AS row_cnt,
        COUNT(DISTINCT "Columns")                                                   AS col_cnt,
        COUNT(DISTINCT TO_JSON(OBJECT_CONSTRUCT('x',"ImagePositionPatient"[0],
                                                'y',"ImagePositionPatient"[1])))   AS xy_pos_cnt,
        COUNT(DISTINCT "SliceThickness")                                            AS thick_cnt,
        COUNT(DISTINCT CAST("ImagePositionPatient"[2] AS FLOAT))                    AS z_cnt,

        /* flags to exclude unwanted instances */
        SUM(CASE WHEN LOWER("ImageType")        LIKE '%localizer%'                                         THEN 1 ELSE 0 END) AS localizer_flag,
        SUM(CASE WHEN "TransferSyntaxUID" IN ('1.2.840.10008.1.2.4.70',
                                              '1.2.840.10008.1.2.4.51')                                    THEN 1 ELSE 0 END) AS jpeg_flag,

        /* orientation components (they are identical across series when orient_cnt = 1) */
        MIN(CAST("ImageOrientationPatient"[0] AS FLOAT)) AS xr,
        MIN(CAST("ImageOrientationPatient"[1] AS FLOAT)) AS yr,
        MIN(CAST("ImageOrientationPatient"[3] AS FLOAT)) AS xc,
        MIN(CAST("ImageOrientationPatient"[4] AS FLOAT)) AS yc
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND LOWER("collection_id") <> 'nlst'               -- exclude NLST
    GROUP BY "SeriesInstanceUID"
),

filtered AS (
    SELECT
        *,
        ABS(xr*yc - yr*xc) AS z_normal
    FROM series_stats
    WHERE orient_cnt   = 1          -- single ImageOrientationPatient
      AND pxspace_cnt  = 1          -- single PixelSpacing
      AND row_cnt      = 1          -- single Rows value
      AND col_cnt      = 1          -- single Columns value
      AND xy_pos_cnt  <= 1          -- consistent x-y image position
      AND thick_cnt    = 1          -- single slice thickness / interval
      AND z_cnt        = num_images -- one image per unique z-position
      AND localizer_flag = 0        -- no LOCALIZER images
      AND jpeg_flag      = 0        -- exclude JPEG-compressed transfer syntaxes
      AND z_normal BETWEEN 0.99 AND 1.01  -- axial (or near-axial) orientation
)

SELECT
    "SeriesInstanceUID",
    "SeriesNumber",
    "PatientID",
    ROUND( total_bytes / (1024*1024) , 2) AS series_size_MiB
FROM filtered
ORDER BY series_size_MiB DESC NULLS LAST
LIMIT 5;