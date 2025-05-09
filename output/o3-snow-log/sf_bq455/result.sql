/*  Top-5 largest CT series (MiB) with quality/consistency filters                      */
WITH inst AS (        /* 1. select CT instances that pass basic filters                */
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID",
        "instance_size",                       -- bytes
        "Rows"                       AS rws,
        "Columns"                    AS cls,
        "PixelSpacing"::STRING       AS px_sp_str,
        ("ImagePositionPatient"[2])::FLOAT   AS z_pos,   -- z-coordinate
        /* direction cosines */
        ("ImageOrientationPatient"[0])::FLOAT AS row_x,
        ("ImageOrientationPatient"[1])::FLOAT AS row_y,
        ("ImageOrientationPatient"[3])::FLOAT AS col_x,
        ("ImageOrientationPatient"[4])::FLOAT AS col_y,
        "XRayTubeCurrentInmA"::FLOAT          AS tube_ma
    FROM IDC.IDC_V17."DICOM_ALL"
    WHERE "Modality" = 'CT'
      AND "collection_id" <> 'nlst'                                   -- exclude NLST
      AND ( "ImageType" IS NULL
             OR LOWER("ImageType"::STRING) NOT LIKE '%localizer%' )
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                      '1.2.840.10008.1.2.4.51')       -- no JPEG-lossy
),
inst2 AS (           /* 2. add orientation z-component                                  */
    SELECT *,
           (row_x*col_y - row_y*col_x) AS ori_z
    FROM inst
),
z_deltas AS (        /* 3. slice-spacing per series                                     */
    SELECT
        "SeriesInstanceUID",
        ROUND(
            ABS( LEAD(z_pos) OVER (PARTITION BY "SeriesInstanceUID" ORDER BY z_pos)
                 - z_pos ), 4) AS dz
    FROM inst2
),
spacing_agg AS (     /* 4. ensure constant spacing                                      */
    SELECT "SeriesInstanceUID",
           COUNT(DISTINCT dz) AS distinct_spacing_cnt
    FROM   z_deltas
    WHERE  dz IS NOT NULL
    GROUP BY "SeriesInstanceUID"
),
series_stats AS (    /* 5. aggregate series-level metrics                               */
    SELECT
        "SeriesInstanceUID",
        MIN("SeriesNumber")  AS series_number,
        MIN("PatientID")     AS patient_id,
        SUM("instance_size")/1048576.0          AS series_size_mib, -- MiB
        COUNT(*)                                AS num_images,
        COUNT(DISTINCT ROUND(z_pos,4))          AS uniq_z,
        COUNT(DISTINCT ROUND(ori_z,4))          AS uniq_ori,
        AVG(ori_z)                              AS avg_ori_z,
        COUNT(DISTINCT px_sp_str)               AS uniq_px_sp,
        COUNT(DISTINCT rws)                     AS uniq_rows,
        COUNT(DISTINCT cls)                     AS uniq_cols,
        COUNT(DISTINCT tube_ma)                 AS uniq_tube
    FROM inst2
    GROUP BY "SeriesInstanceUID"
),
qualified AS (       /* 6. apply all quality filters                                    */
    SELECT s.*
    FROM   series_stats s
    JOIN   spacing_agg sp
           ON s."SeriesInstanceUID" = sp."SeriesInstanceUID"
    WHERE  s.num_images > 1
      AND  s.num_images = s.uniq_z                 -- no duplicate z positions
      AND  sp.distinct_spacing_cnt = 1             -- constant slice spacing
      AND  s.uniq_ori = 1
      AND  ABS(s.avg_ori_z) BETWEEN 0.99 AND 1.01  -- axial alignment
      AND  s.uniq_px_sp = 1
      AND  s.uniq_rows  = 1
      AND  s.uniq_cols  = 1
      AND  (s.uniq_tube <= 1 OR s.uniq_tube IS NULL)  -- consistent exposure
)
/* 7. return top 5 largest qualifying series                                            */
SELECT
    "SeriesInstanceUID",
    series_number              AS "SeriesNumber",
    patient_id                 AS "PatientID",
    ROUND(series_size_mib, 2)  AS "SeriesSize_MiB"
FROM   qualified
ORDER BY series_size_mib DESC NULLS LAST
LIMIT 5;