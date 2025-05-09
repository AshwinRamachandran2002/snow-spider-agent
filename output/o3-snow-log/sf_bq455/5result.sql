WITH initial AS (          -- 1) basic filtering at the instance level
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID",
        "instance_size",
        "Rows",
        "Columns",
        "Exposure",
        TO_JSON("PixelSpacing")        AS pixel_spacing_str,
        TO_JSON("ImageOrientationPatient") AS orientation_str,
        CAST("ImageOrientationPatient"[0] AS FLOAT) AS iop0,
        CAST("ImageOrientationPatient"[1] AS FLOAT) AS iop1,
        CAST("ImageOrientationPatient"[3] AS FLOAT) AS iop3,
        CAST("ImageOrientationPatient"[4] AS FLOAT) AS iop4,
        CAST("ImagePositionPatient"[2]  AS FLOAT)   AS z_pos      -- z-coordinate
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND "collection_id" <> 'nlst'                              -- not NLST
      AND (UPPER(CAST("ImageType" AS STRING)) NOT LIKE '%LOCALIZER%')
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                      '1.2.840.10008.1.2.4.51')  -- no JPEG-lossy
),
with_normal AS (            -- 2) compute slice‐normal (cross-product z-component)
    SELECT  *,
            (iop0*iop4 - iop1*iop3) AS normal_z
    FROM    initial
),
z_sorted AS (               -- 3) order slices per series to get inter-slice gaps
    SELECT  *,
            ROW_NUMBER() OVER (PARTITION BY "SeriesInstanceUID"
                               ORDER BY z_pos) AS rn
    FROM    with_normal
),
z_diff AS (                 -- 4) differences between successive z positions
    SELECT  "SeriesInstanceUID",
            ABS(LEAD(z_pos) OVER (PARTITION BY "SeriesInstanceUID"
                                   ORDER BY z_pos) - z_pos) AS spacing
    FROM    z_sorted
),
spacing_check AS (          -- 5) enforce identical slice spacing
    SELECT  "SeriesInstanceUID",
            COUNT(DISTINCT ROUND(spacing,5)) AS spacing_count
    FROM    z_diff
    WHERE   spacing IS NOT NULL AND spacing > 0
    GROUP BY "SeriesInstanceUID"
),
series_stats AS (           -- 6) series-level consistency metrics
    SELECT
        "SeriesInstanceUID",
        MIN("SeriesNumber") AS "SeriesNumber",
        MIN("PatientID")    AS "PatientID",
        SUM("instance_size")                    AS total_bytes,
        COUNT(*)                                AS num_images,
        COUNT(DISTINCT z_pos)                   AS unique_z,
        COUNT(DISTINCT orientation_str)         AS n_orientation,
        COUNT(DISTINCT pixel_spacing_str)       AS n_pixelspacing,
        COUNT(DISTINCT "Exposure")              AS n_exposure,
        COUNT(DISTINCT "Rows")                  AS n_rows,
        COUNT(DISTINCT "Columns")               AS n_cols,
        AVG(normal_z)                           AS avg_normal_z
    FROM   with_normal
    GROUP BY "SeriesInstanceUID"
)
-- 7) final selection, ordering and limiting
SELECT
    s."SeriesInstanceUID",
    s."SeriesNumber",
    s."PatientID",
    ROUND(s.total_bytes / 1048576.0 , 2) AS series_size_mib
FROM   series_stats      s
JOIN   spacing_check     sp  ON s."SeriesInstanceUID" = sp."SeriesInstanceUID"
WHERE  s.num_images            = s.unique_z           -- no duplicate slices
  AND  s.n_orientation         = 1                    -- one IOP value
  AND  s.n_pixelspacing        = 1                    -- one pixel spacing
  AND  s.n_exposure            = 1                    -- one exposure level
  AND  s.n_rows                = 1                    -- constant rows
  AND  s.n_cols                = 1                    -- constant columns
  AND  sp.spacing_count        = 1                    -- uniform slice interval
  AND  ABS(s.avg_normal_z) BETWEEN 0.99 AND 1.01      -- axial / coronal alignment
ORDER BY series_size_mib DESC NULLS LAST
LIMIT 5;