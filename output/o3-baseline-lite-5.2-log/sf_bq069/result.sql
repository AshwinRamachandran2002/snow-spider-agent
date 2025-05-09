/*  CT‑SERIES QA REPORT  -------------------------------------------------------
    • Exclude NLST collection
    • Skip JPEG‑compressed & LOCALIZER images
    • Geometry QA on series
    • Compute slice‑spacing & exposure statistics
-------------------------------------------------------------------------------*/
WITH inst AS (   /* ------------------------------------------------ 1. instances */
    SELECT
        "SeriesInstanceUID"                                           AS series_uid ,
        "SeriesNumber"                                                AS series_number ,
        "StudyInstanceUID"                                            AS study_uid ,
        "PatientID"                                                   AS patient_id ,

        /* orientation components (cast via STRING) */
        TRY_TO_DOUBLE("ImageOrientationPatient"[0]::STRING)           AS io0 ,
        TRY_TO_DOUBLE("ImageOrientationPatient"[1]::STRING)           AS io1 ,
        TRY_TO_DOUBLE("ImageOrientationPatient"[3]::STRING)           AS io3 ,
        TRY_TO_DOUBLE("ImageOrientationPatient"[4]::STRING)           AS io4 ,

        TO_VARCHAR("ImageOrientationPatient")                         AS orient_str ,
        TO_VARCHAR("PixelSpacing")                                    AS pixspace_str ,

        /* position components */
        TRY_TO_DOUBLE("ImagePositionPatient"[0]::STRING)              AS pos_x ,
        TRY_TO_DOUBLE("ImagePositionPatient"[1]::STRING)              AS pos_y ,
        TRY_TO_DOUBLE("ImagePositionPatient"[2]::STRING)              AS pos_z ,
        TO_VARCHAR("ImagePositionPatient")                            AS pos_str ,

        TRY_TO_DOUBLE(NULLIF("SliceThickness", '')::STRING)           AS slice_thick ,
        TRY_TO_DOUBLE(NULLIF("Exposure"      , '')::STRING)           AS exposure_val ,

        "Rows"                                                        AS n_rows ,
        "Columns"                                                     AS n_cols ,

        /* |(row×col)·[0,0,1]| */
        ABS(
              TRY_TO_DOUBLE("ImageOrientationPatient"[0]::STRING)
            * TRY_TO_DOUBLE("ImageOrientationPatient"[4]::STRING)
            - TRY_TO_DOUBLE("ImageOrientationPatient"[1]::STRING)
            * TRY_TO_DOUBLE("ImageOrientationPatient"[3]::STRING)
        )                                                             AS dir_dot ,

        "instance_size"                                               AS inst_size
    FROM  IDC.IDC_V17.DICOM_ALL
    WHERE "Modality"          = 'CT'
      AND "collection_name"  <> 'NLST'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                      '1.2.840.10008.1.2.4.51')
      AND UPPER(TO_VARCHAR("ImageType")) NOT LIKE '%LOCALIZER%'
),

/* ------------------------------------------------------------- 2. slice spacing Δz */
dz AS (
    SELECT
        series_uid,
        ABS(pos_z
          - LAG(pos_z) OVER (PARTITION BY series_uid ORDER BY pos_z))   AS dz
    FROM inst
    QUALIFY dz IS NOT NULL
),

/* --------------------------------------------- 3. per‑series aggregation & QA */
agg AS (
    SELECT
        series_uid,
        MIN(series_number)                                        AS series_number ,
        MIN(study_uid)                                            AS study_uid ,
        MIN(patient_id)                                           AS patient_id ,
        MAX(dir_dot)                                              AS max_dir_dot ,
        COUNT(*)                                                  AS num_instances ,

        COUNT(DISTINCT orient_str)                                AS cnt_orient ,
        COUNT(DISTINCT pixspace_str)                              AS cnt_pixspace ,
        COUNT(DISTINCT n_rows)                                    AS cnt_rows ,
        COUNT(DISTINCT n_cols)                                    AS cnt_cols ,
        COUNT(DISTINCT pos_str)                                   AS cnt_pos ,
        COUNT(DISTINCT CONCAT(TO_VARCHAR(pos_x),',',TO_VARCHAR(pos_y))) AS cnt_xy ,

        COUNT(DISTINCT slice_thick)                               AS distinct_slice_thick ,
        COUNT(DISTINCT exposure_val)                              AS distinct_exposure_vals ,
        MAX(exposure_val)                                         AS max_exposure ,
        MIN(exposure_val)                                         AS min_exposure ,
        MAX(exposure_val) - MIN(exposure_val)                     AS exposure_range ,
        SUM(inst_size)/1048576.0                                  AS series_size_mib
    FROM inst
    GROUP BY series_uid
    HAVING
            cnt_orient   = 1              /* one orientation value            */
        AND cnt_pixspace = 1              /* identical pixel spacing          */
        AND cnt_rows     = 1              /* identical rows                   */
        AND cnt_cols     = 1              /* identical columns                */
        AND num_instances = cnt_pos       /* #instances = #unique z‑positions */
        AND cnt_xy       = 1              /* identical X‑Y components         */
        AND max_dir_dot  >= 0.99          /* near‑unity alignment             */
),

/* ----------------------------------------- 4. Δz statistics for passed series */
dzagg AS (
    SELECT
        series_uid,
        MAX(dz)                                AS max_dz ,
        MIN(dz)                                AS min_dz ,
        MAX(dz) - MIN(dz)                      AS dz_tolerance
    FROM dz
    GROUP BY series_uid
)

/* --------------------------------------------------------------- 5. final report */
SELECT
    a.series_uid                  AS "SeriesInstanceUID",
    a.series_number               AS "SeriesNumber",
    a.study_uid                   AS "StudyInstanceUID",
    a.patient_id                  AS "PatientID",
    a.max_dir_dot                 AS "MaxDirDotProduct",
    a.num_instances               AS "NumInstances",
    a.distinct_slice_thick        AS "DistinctSliceThicknessValues",
    dz.max_dz                     AS "MaxSliceIntervalDiff",
    dz.min_dz                     AS "MinSliceIntervalDiff",
    dz.dz_tolerance               AS "SliceIntervalTolerance",
    a.distinct_exposure_vals      AS "DistinctExposureValues",
    a.max_exposure                AS "MaxExposure",
    a.min_exposure                AS "MinExposure",
    a.exposure_range              AS "ExposureRange",
    a.series_size_mib             AS "SeriesSizeMiB"
FROM   agg   a
JOIN   dzagg dz
  ON   a.series_uid = dz.series_uid
ORDER BY
    dz.dz_tolerance  DESC NULLS LAST,
    a.exposure_range DESC NULLS LAST,
    a.series_uid     DESC;