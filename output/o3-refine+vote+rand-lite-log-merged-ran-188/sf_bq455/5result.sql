WITH filtered_ct AS (
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID",
        "instance_size",
        "ImageType",
        "TransferSyntaxUID",
        "ImageOrientationPatient",
        "PixelSpacing",
        "Rows",
        "Columns",
        "ImagePositionPatient",
        "KVP"
    FROM IDC.IDC_V17."DICOM_ALL"
    WHERE "Modality" = 'CT'
      AND "collection_id" <> 'nlst'                                   -- exclude NLST
      AND "TransferSyntaxUID" NOT IN (                                -- exclude JPEG-compressed
            '1.2.840.10008.1.2.4.70',
            '1.2.840.10008.1.2.4.51')
      AND ( "ImageType" IS NULL OR                                    -- exclude LOCALIZER
            "ImageType" NOT ILIKE '%LOCALIZER%' )
),

series_stats AS (
    SELECT
        "SeriesInstanceUID",
        MIN("SeriesNumber")                            AS "SeriesNumber",
        MIN("PatientID")                               AS "PatientID",
        COUNT(*)                                       AS num_images,
        ROUND( SUM("instance_size")/(1024*1024), 2)    AS series_size_mib,

        /* consistency counts */
        COUNT(DISTINCT "ImageOrientationPatient")                          AS orient_cnt,
        COUNT(DISTINCT "PixelSpacing")                                     AS pixspace_cnt,
        COUNT(DISTINCT "Rows")                                             AS rows_cnt,
        COUNT(DISTINCT "Columns")                                          AS cols_cnt,
        COUNT(DISTINCT 
              TO_VARCHAR(("ImagePositionPatient"[0]))||','||
              TO_VARCHAR(("ImagePositionPatient"[1])) )                    AS xy_pos_cnt,
        COUNT(DISTINCT ( "ImagePositionPatient"[2] )::FLOAT )              AS z_pos_cnt,
        COUNT(DISTINCT "KVP")                                              AS kvp_cnt,

        /* z–component of cross-product of direction cosines */
        MIN( ABS( ( ("ImageOrientationPatient"[0])::FLOAT * ("ImageOrientationPatient"[4])::FLOAT )
                 - ( ("ImageOrientationPatient"[1])::FLOAT * ("ImageOrientationPatient"[3])::FLOAT ) ) )  AS min_abs_k,
        MAX( ABS( ( ("ImageOrientationPatient"[0])::FLOAT * ("ImageOrientationPatient"[4])::FLOAT )
                 - ( ("ImageOrientationPatient"[1])::FLOAT * ("ImageOrientationPatient"[3])::FLOAT ) ) )  AS max_abs_k
    FROM filtered_ct
    GROUP BY "SeriesInstanceUID"
),

qualified AS (
    SELECT *
    FROM series_stats
    WHERE orient_cnt  = 1          -- single ImageOrientationPatient value
      AND pixspace_cnt = 1         -- single PixelSpacing value
      AND rows_cnt     = 1         -- single Rows
      AND cols_cnt     = 1         -- single Columns
      AND xy_pos_cnt   = 1         -- identical (x,y) position for all slices
      AND num_images   = z_pos_cnt -- no duplicate z-positions
      AND min_abs_k >= 0.99
      AND max_abs_k <= 1.01        -- plane alignment check
      AND kvp_cnt    <= 1          -- consistent exposure (KVP)
)

SELECT
    "SeriesInstanceUID",
    "SeriesNumber",
    "PatientID",
    series_size_mib
FROM qualified
ORDER BY series_size_mib DESC NULLS LAST
LIMIT 5;