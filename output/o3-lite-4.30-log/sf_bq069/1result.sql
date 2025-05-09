/*  ------------------------------------------------------------
    CT‑Series QA Report  (Snowflake SQL)

    • Exclude NLST, JPEG‑compressed, and LOCALIZER series
    • Geometry checks:
        – single ImageOrientationPatient & PixelSpacing value
        – identical Rows / Columns
        – identical first two ImagePositionPatient components
        – #SOP instances  =  #distinct ImagePositionPatient (z)
        – | (IOP₁×IOP₂)·[0,0,1] |  within 0.01 of 1
    • Metrics per series (rounded to 4 decimals whenever required):
        series_instance_uid, collection, num_images,
        mean_slice_interval_mm, diff_slice_interval_mm,
        mean_exposure_mAs,    diff_exposure_mAs,
        series_size_mb
    ------------------------------------------------------------  */
WITH base AS (
    SELECT
        "SeriesInstanceUID"                      AS series_uid ,
        "SeriesNumber"                           AS series_number ,
        "StudyInstanceUID"                       AS study_uid ,
        "PatientID"                              AS patient_id ,
        "collection_name"                        AS collection ,

        TO_VARCHAR("ImageOrientationPatient")    AS iop_raw ,
        TO_VARCHAR("PixelSpacing")               AS ps_raw ,
        TO_VARCHAR("ImagePositionPatient")       AS ipp_raw ,
        "Rows"                                   AS n_rows ,
        "Columns"                                AS n_cols ,
        "SliceThickness"                         AS slice_thickness ,
        REGEXP_REPLACE(TO_VARCHAR("Exposure"), '[\\[\\]\"]' , '' )  AS exposure_str ,
        "instance_size"                          AS instance_size
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality"        = 'CT'
      AND "collection_name" <> 'NLST'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70','1.2.840.10008.1.2.4.51')
      AND ( "ImageType" IS NULL OR TO_VARCHAR("ImageType") NOT ILIKE '%LOCALIZER%' )
), parsed AS (
    SELECT *,
        REGEXP_REPLACE(iop_raw , '[\\[\\]\"]','') AS iop_clean ,
        REGEXP_REPLACE(ps_raw  , '[\\[\\]\"]','') AS ps_clean ,
        REGEXP_REPLACE(ipp_raw , '[\\[\\]\"]','') AS ipp_clean
    FROM base
), numeric AS (
    SELECT
        series_uid, series_number, study_uid, patient_id, collection,
        ps_clean, ipp_clean, n_rows, n_cols, slice_thickness,
        TRY_TO_NUMBER(exposure_str)                         AS exposure_val,
        instance_size,

        /* 6‑tuple orientation */
        TRY_TO_NUMBER(SPLIT_PART(iop_clean, ',', 1)) AS a ,
        TRY_TO_NUMBER(SPLIT_PART(iop_clean, ',', 2)) AS b ,
        TRY_TO_NUMBER(SPLIT_PART(iop_clean, ',', 3)) AS c ,
        TRY_TO_NUMBER(SPLIT_PART(iop_clean, ',', 4)) AS d ,
        TRY_TO_NUMBER(SPLIT_PART(iop_clean, ',', 5)) AS e ,
        TRY_TO_NUMBER(SPLIT_PART(iop_clean, ',', 6)) AS f ,

        /* 3‑tuple position */
        TRY_TO_NUMBER(SPLIT_PART(ipp_clean, ',', 1)) AS x_pos ,
        TRY_TO_NUMBER(SPLIT_PART(ipp_clean, ',', 2)) AS y_pos ,
        TRY_TO_NUMBER(SPLIT_PART(ipp_clean, ',', 3)) AS z_pos
    FROM parsed
), with_dp AS (
    /* absolute dot product of orientation cross‑product vs Z‑axis */
    SELECT *,
           ABS((a*e) - (b*d))                    AS dp_abs
    FROM numeric
), zdiff AS (
    /* consecutive z differences for slice interval stats */
    SELECT
        series_uid, study_uid, patient_id, collection,
        series_number, z_pos,
        LAG(z_pos) OVER (PARTITION BY series_uid ORDER BY z_pos) AS prev_z,
        exposure_val, slice_thickness,
        n_rows, n_cols, ps_clean, dp_abs,
        x_pos, y_pos, instance_size
    FROM with_dp
), geo_pass AS (
    /* geometry & consistency filters per series */
    SELECT
        series_uid,
        COUNT(*)                           AS num_imgs,
        COUNT(DISTINCT ps_clean)           AS ps_variants,
        MAX(ABS(dp_abs - 1))               AS max_dp_delta,
        COUNT(DISTINCT n_rows)             AS row_vars,
        COUNT(DISTINCT n_cols)             AS col_vars,
        COUNT(DISTINCT TO_VARCHAR(x_pos))  AS x_vars,
        COUNT(DISTINCT TO_VARCHAR(y_pos))  AS y_vars,
        COUNT(DISTINCT TO_VARCHAR(z_pos))  AS z_vars
    FROM with_dp
    GROUP BY series_uid
    HAVING
          ps_variants = 1
      AND row_vars    = 1
      AND col_vars    = 1
      AND x_vars      = 1
      AND y_vars      = 1
      AND z_vars      = num_imgs
      AND max_dp_delta <= 0.01
), final AS (
    /* compute requested metrics for qualified series */
    SELECT
        g.series_uid                                   AS series_instance_uid ,
        MAX(z.collection)                              AS collection ,
        g.num_imgs                                     AS num_images ,

        ROUND(AVG(ABS(z.z_pos - z.prev_z)), 4)         AS mean_slice_interval_mm ,
        ROUND( MAX(ABS(z.z_pos - z.prev_z))
             - MIN(ABS(z.z_pos - z.prev_z)), 4)        AS diff_slice_interval_mm ,

        ROUND(AVG(z.exposure_val), 4)                  AS mean_exposure_mAs ,
        ROUND( MAX(z.exposure_val) - MIN(z.exposure_val), 4)
                                                      AS diff_exposure_mAs ,

        ROUND(SUM(z.instance_size)/1048576, 2)         AS series_size_mb
    FROM geo_pass g
    JOIN zdiff z
      ON g.series_uid = z.series_uid
    WHERE z.prev_z IS NOT NULL                         -- need ≥2 slices
    GROUP BY g.series_uid , g.num_imgs
)
SELECT
    series_instance_uid,
    collection,
    num_images,
    mean_slice_interval_mm,
    diff_slice_interval_mm,
    mean_exposure_mAs,
    diff_exposure_mAs,
    series_size_mb
FROM final
ORDER BY
      diff_slice_interval_mm DESC NULLS LAST,
      diff_exposure_mAs      DESC NULLS LAST,
      series_instance_uid    DESC;