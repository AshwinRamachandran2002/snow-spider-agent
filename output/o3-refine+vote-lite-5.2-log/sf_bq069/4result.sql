/*  CT series that fulfil the requested QC/geometry rules and additional
    study/series level statistics                                          */
WITH inst AS (
    /* ------------------------------------------------------------------ *
     * 1) keep only CT instances that satisfy the easy‑to‑state filters   *
     * ------------------------------------------------------------------ */
    SELECT
        /* identifiers --------------------------------------------------- */
        "SeriesInstanceUID"                                                     AS series_uid ,
        "SeriesNumber"                                                          AS series_number ,
        "StudyInstanceUID"                                                      AS study_uid ,
        "PatientID"                                                             AS patient_id ,

        /* geometry ------------------------------------------------------ */
        "Rows"                                                                  AS im_rows ,
        "Columns"                                                               AS im_cols ,
        TO_VARCHAR( "ImageOrientationPatient" )                                 AS orient_str ,
        "ImageOrientationPatient"[0]::FLOAT                                     AS ox ,
        "ImageOrientationPatient"[1]::FLOAT                                     AS oy ,
        "ImageOrientationPatient"[2]::FLOAT                                     AS oz ,
        "ImageOrientationPatient"[3]::FLOAT                                     AS px ,
        "ImageOrientationPatient"[4]::FLOAT                                     AS py ,
        "ImageOrientationPatient"[5]::FLOAT                                     AS pz ,
        TO_VARCHAR( "PixelSpacing" )                                            AS pixsp_str ,
        /* 3‑rd (z) component of ImagePositionPatient -------------------- */
        "ImagePositionPatient"[2]::FLOAT                                        AS z_pos ,

        /* image & acquisition ------------------------------------------- */
        "SliceThickness"                                                        AS slice_thk ,
        TRY_TO_NUMBER( "Exposure" )                                             AS exposure_val ,
        "instance_size"                                                         AS inst_size ,

        /* per‑instance normal‑vector dot product with (0,0,1) ----------- */
        ABS(
            ( ox * py - oy * px )        /* N_z component (cross(ox..)·k) */
        )                                                                       AS abs_dot_prod
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE  "Modality"            =  'CT'
      AND LOWER("collection_id") != 'nlst'                      /* exclude NLST          */
      AND "TransferSyntaxUID" NOT IN (                          /* skip JPEG compressed  */
            '1.2.840.10008.1.2.4.70' ,      /* JPEG‑LS           */
            '1.2.840.10008.1.2.4.51' )      /* JPEG baseline     */
      AND NOT UPPER( TO_VARCHAR("ImageType") ) LIKE '%LOCALIZER%'    /* no localizers  */
),
/* ---------------------------------------------------------------------- *
 * 2) add per‑instance slice‑to‑slice distance inside every series        *
 * ---------------------------------------------------------------------- */
seq_with_diff AS (
    SELECT
        inst.* ,
        /* absolute z–gap to previous slice after sorting by z‑coordinate */
        ABS( z_pos - LAG( z_pos ) OVER (PARTITION BY series_uid
                                        ORDER BY      z_pos) )           AS z_gap
    FROM inst
),
/* ---------------------------------------------------------------------- *
 * 3) series‑level aggregations & QC filters                              *
 * ---------------------------------------------------------------------- */
series_qc AS (
    SELECT
        series_uid                                                               ,
        MIN( series_number )                               AS series_number      ,
        MIN( study_uid   )                                 AS study_uid          ,
        MIN( patient_id  )                                 AS patient_id         ,

        /* geometry checks ------------------------------------------------ */
        MAX( abs_dot_prod )                                AS max_dot_prod       ,
        COUNT(*)                                           AS n_instances        ,
        COUNT(DISTINCT TO_VARCHAR(z_pos))                  AS n_pos_vals         ,
        COUNT(DISTINCT orient_str)                         AS n_orient_vals      ,
        COUNT(DISTINCT pixsp_str)                          AS n_pixsp_vals       ,
        MIN(im_rows)                                       AS min_rows           ,
        MAX(im_rows)                                       AS max_rows           ,
        MIN(im_cols)                                       AS min_cols           ,
        MAX(im_cols)                                       AS max_cols           ,

        /* slice interval statistics ------------------------------------- */
        COUNT(DISTINCT slice_thk)                          AS n_slice_thk_vals   ,
        MAX(z_gap)                                         AS max_z_gap          ,
        MIN(z_gap)                                         AS min_z_gap          ,
        ( MAX(z_gap) - MIN(z_gap) )                        AS z_gap_tolerance    ,

        /* exposure statistics ------------------------------------------- */
        COUNT(DISTINCT exposure_val)                       AS n_exposure_vals    ,
        MAX(exposure_val)                                  AS max_exposure       ,
        MIN(exposure_val)                                  AS min_exposure       ,
        ( MAX(exposure_val) - MIN(exposure_val) )          AS exposure_range     ,

        /* series size in MiB -------------------------------------------- */
        SUM(inst_size) / 1048576                           AS series_size_mib
    FROM seq_with_diff
    GROUP BY series_uid
    HAVING          /*  QC rules  */
           n_orient_vals   = 1
       AND n_pixsp_vals    = 1
       AND n_instances     = n_pos_vals
       AND max_rows        = min_rows
       AND max_cols        = min_cols
       AND max_dot_prod BETWEEN 0.99 AND 1.01          /* 1 ± 0.01 */
),
/* ---------------------------------------------------------------------- *
 * 4) final selection & ordering                                          *
 * ---------------------------------------------------------------------- */
final_report AS (
    SELECT
        series_uid                 AS "SeriesInstanceUID"                        ,
        series_number              AS "SeriesNumber"                             ,
        study_uid                  AS "StudyInstanceUID"                         ,
        patient_id                 AS "PatientID"                                ,
        max_dot_prod               AS "Max_DotProduct"                           ,
        n_instances                AS "Num_SOPInstances"                         ,
        n_slice_thk_vals           AS "Num_Distinct_SliceThickness"              ,
        max_z_gap                  AS "Max_Z_Interval"                           ,
        min_z_gap                  AS "Min_Z_Interval"                           ,
        z_gap_tolerance            AS "Z_Interval_Tolerance"                     ,
        n_exposure_vals            AS "Num_Distinct_Exposure"                    ,
        max_exposure               AS "Max_Exposure"                             ,
        min_exposure               AS "Min_Exposure"                             ,
        exposure_range             AS "Exposure_Range"                           ,
        series_size_mib            AS "Series_Size_MiB"
    FROM series_qc
)
SELECT *
FROM final_report
ORDER BY
      "Z_Interval_Tolerance" DESC NULLS LAST ,
      "Exposure_Range"       DESC NULLS LAST ,
      "SeriesInstanceUID"    DESC ;