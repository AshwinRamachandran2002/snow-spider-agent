/*  -----------------------------------------------------------
    CT series quality report  (Snowflake SQL)

    Output columns (exact names):
      series_instance_uid,
      collection,
      num_images,
      mean_slice_interval_mm,
      diff_slice_interval_mm,
      mean_exposure_mAs,
      diff_exposure_mAs,
      series_size_mb
   ----------------------------------------------------------- */
WITH filtered AS (   -- 1️⃣  row‑level pre‑filter
    SELECT
        "SeriesInstanceUID"               AS series_uid ,
        "collection_name"                 AS collection ,
        TRY_TO_NUMBER("Exposure")         AS exposure_num ,
        "instance_size"                   AS instance_size ,
        TRY_TO_NUMBER("SliceThickness")   AS slice_thickness ,
        /* dot‑product of cross(row‑vec , col‑vec) with k‑unit‑vec */
        (   ("ImageOrientationPatient"[0]::FLOAT * "ImageOrientationPatient"[4]::FLOAT)
          - ("ImageOrientationPatient"[1]::FLOAT * "ImageOrientationPatient"[3]::FLOAT)
        )                                 AS dot_k ,
        "ImageOrientationPatient"::STRING AS orient_str ,
        "PixelSpacing"::STRING            AS px_spacing_str ,
        "Rows"                             AS rows_cnt ,
        "Columns"                          AS cols_cnt ,
        "ImagePositionPatient"::STRING     AS ipp_str ,
        "ImagePositionPatient"[0]::STRING  AS ipp_x_str ,
        "ImagePositionPatient"[1]::STRING  AS ipp_y_str ,
        "ImagePositionPatient"[2]::FLOAT   AS ipp_z
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND "collection_name" <> 'NLST'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                      '1.2.840.10008.1.2.4.51')
      AND UPPER("ImageType"::STRING) NOT ILIKE '%LOCALIZER%'
),
with_spacing AS (    -- 2️⃣  per‑slice z‑spacing
    SELECT
        f.*,
        ABS( f.ipp_z
             - LAG(f.ipp_z) OVER (PARTITION BY series_uid ORDER BY f.ipp_z)
        ) AS z_spacing
    FROM filtered f
),
series_agg AS (      -- 3️⃣  per‑series aggregation & helper stats
    SELECT
        series_uid,
        MAX(collection)                           AS collection,
        COUNT(DISTINCT orient_str)                AS distinct_orient,
        COUNT(DISTINCT px_spacing_str)            AS distinct_px_spacing,
        COUNT(DISTINCT rows_cnt)                  AS distinct_rows,
        COUNT(DISTINCT cols_cnt)                  AS distinct_cols,
        COUNT(*)                                  AS sop_cnt,
        COUNT(DISTINCT ipp_str)                   AS ipp_distinct,
        COUNT(DISTINCT (ipp_x_str||'|'||ipp_y_str)) AS xy_distinct,
        MAX(ABS(dot_k))                           AS max_dot_k,

        AVG(z_spacing)                            AS mean_z_spacing,
        MIN(z_spacing)                            AS min_z_spacing,
        MAX(z_spacing)                            AS max_z_spacing,

        AVG(exposure_num)                         AS mean_exposure,
        MIN(exposure_num)                         AS min_exposure,
        MAX(exposure_num)                         AS max_exposure,

        ROUND(SUM(instance_size)/1048576 , 4)     AS series_size_mb
    FROM with_spacing
    GROUP BY series_uid
),
qualified AS (       -- 4️⃣  apply geometry / consistency rules
    SELECT *,
           (max_z_spacing - min_z_spacing) AS diff_slice_interval,
           (max_exposure   - min_exposure) AS diff_exposure
    FROM series_agg
    WHERE distinct_orient      = 1
      AND distinct_px_spacing  = 1
      AND distinct_rows        = 1
      AND distinct_cols        = 1
      AND sop_cnt              = ipp_distinct
      AND xy_distinct          = 1
      AND max_dot_k BETWEEN 0.99 AND 1.01
)
SELECT
    series_uid                               AS series_instance_uid,
    collection,
    sop_cnt                                  AS num_images,
    ROUND(mean_z_spacing ,4)                 AS mean_slice_interval_mm,
    ROUND(diff_slice_interval ,4)            AS diff_slice_interval_mm,
    ROUND(mean_exposure ,4)                  AS mean_exposure_mAs,
    ROUND(diff_exposure ,4)                  AS diff_exposure_mAs,
    series_size_mb                           AS series_size_mb
FROM qualified
ORDER BY
      diff_slice_interval_mm DESC NULLS LAST,
      diff_exposure_mAs      DESC NULLS LAST,
      series_instance_uid    DESC;