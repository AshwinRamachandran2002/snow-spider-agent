/*───────────────────────────────────────────────────────────────────────────────
  Top‑5 largest CT series (MiB) that meet the requested quality/consistency
  constraints (Snowflake SQL)
───────────────────────────────────────────────────────────────────────────────*/
WITH slices AS (   -- pick only CT, exclude NLST, keep needed columns
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
        "SliceThickness",
        "Exposure",
        "ImagePositionPatient"[0]::FLOAT AS ip_x,
        "ImagePositionPatient"[1]::FLOAT AS ip_y,
        "ImagePositionPatient"[2]::FLOAT AS ip_z
    FROM  IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND "collection_id" <> 'nlst'           -- omit NLST collection
),
/* z–spacing (slice interval) per series */
delta_z AS (
    SELECT
        "SeriesInstanceUID",
        ROUND(ip_z - LAG(ip_z) OVER (PARTITION BY "SeriesInstanceUID"
                                     ORDER BY ip_z), 5) AS dz
    FROM slices
    QUALIFY LAG(ip_z) OVER (PARTITION BY "SeriesInstanceUID"
                            ORDER BY ip_z) IS NOT NULL
),
delta_stats AS (      -- how many distinct slice intervals in a series
    SELECT "SeriesInstanceUID",
           COUNT(DISTINCT dz) AS dz_var_cnt
    FROM   delta_z
    GROUP BY "SeriesInstanceUID"
),
series_stats AS (     -- aggregate everything needed per series
    SELECT
        s."SeriesInstanceUID",
        MIN(s."SeriesNumber")  AS "SeriesNumber",
        MIN(s."PatientID")     AS "PatientID",
        SUM(s."instance_size") AS total_bytes,
        COUNT(*)               AS img_cnt,
        
        /* consistency checks */
        COUNT(DISTINCT s.ip_z)                                         AS z_cnt,
        COUNT(DISTINCT ARRAY_CONSTRUCT(s.ip_x, s.ip_y))                AS xy_cnt,
        COUNT(DISTINCT s."ImageOrientationPatient")                    AS orient_cnt,
        COUNT(DISTINCT s."PixelSpacing")                               AS pxsp_cnt,
        COUNT(DISTINCT s."Rows")                                       AS row_cnt,
        COUNT(DISTINCT s."Columns")                                    AS col_cnt,
        COUNT(DISTINCT s."SliceThickness")                             AS thick_cnt,
        COUNT(DISTINCT s."Exposure")                                   AS expos_cnt,
        
        /* disqualifiers */
        MAX(CASE WHEN s."ImageType" ILIKE '%LOCALIZER%' THEN 1 ELSE 0 END)           AS has_localizer,
        MAX(CASE WHEN s."TransferSyntaxUID" IN ('1.2.840.10008.1.2.4.70',
                                                '1.2.840.10008.1.2.4.51')
                 THEN 1 ELSE 0 END)                                                  AS is_jpeg,
        
        /* orientation components for cross‑product z‑axis check */
        MIN(s."ImageOrientationPatient"[0]::FLOAT) AS a,
        MIN(s."ImageOrientationPatient"[1]::FLOAT) AS b,
        MIN(s."ImageOrientationPatient"[3]::FLOAT) AS d,
        MIN(s."ImageOrientationPatient"[4]::FLOAT) AS e
    FROM  slices s
    GROUP BY s."SeriesInstanceUID"
)
/*──────────────────────────────────────────────────────────────*/
SELECT
    ss."SeriesInstanceUID",
    ss."SeriesNumber",
    ss."PatientID",
    ROUND(ss.total_bytes / (1024*1024), 4) AS "SeriesSize_MiB"
FROM   series_stats      ss
JOIN   delta_stats       dz  USING ("SeriesInstanceUID")
WHERE
        ss.has_localizer = 0          -- no localizer images
    AND ss.is_jpeg      = 0           -- not JPEG‑compressed
    /* consistency: one and only one value for each attribute                */
    AND ss.orient_cnt   = 1
    AND ss.pxsp_cnt     = 1
    AND ss.row_cnt      = 1
    AND ss.col_cnt      = 1
    AND ss.thick_cnt    = 1
    AND ss.expos_cnt    <= 1
    AND ss.xy_cnt       = 1           -- same xy position for all slices
    /* slice interval consistency (exactly one unique Δz)                    */
    AND dz.dz_var_cnt   = 1
    /* no duplicate slices: images == unique z positions                      */
    AND ss.img_cnt      = ss.z_cnt
    /* orientation plane check                                               */
    AND ABS(ss.a*ss.e - ss.b*ss.d) BETWEEN 0.99 AND 1.01
ORDER BY ss.total_bytes DESC NULLS LAST
LIMIT 5;