/* ------------------------------------------------------------------
   Quality‑checked CT series, excluding NLST & compressed/localizer
   ------------------------------------------------------------------ */
WITH inst AS (                /* instance–level information */
    SELECT
        "SeriesInstanceUID"                                AS series_uid ,
        "SeriesNumber"                                     AS series_no ,
        "StudyInstanceUID"                                 AS study_uid ,
        "PatientID"                                        AS patient_id ,

        /* numeric components of ImageOrientationPatient              */
        TRY_TO_DOUBLE( ("ImageOrientationPatient"[0])::STRING ) AS r_x ,
        TRY_TO_DOUBLE( ("ImageOrientationPatient"[1])::STRING ) AS r_y ,
        TRY_TO_DOUBLE( ("ImageOrientationPatient"[3])::STRING ) AS c_x ,
        TRY_TO_DOUBLE( ("ImageOrientationPatient"[4])::STRING ) AS c_y ,

        /* stringified values for equality checks                     */
        "ImageOrientationPatient"::STRING                  AS ori_str ,
        "PixelSpacing"::STRING                             AS pixsp_str ,
        ("ImagePositionPatient"[0])::STRING || ',' ||
        ("ImagePositionPatient"[1])::STRING                AS ipp_xy_str ,
        "ImagePositionPatient"::STRING                     AS ipp_full_str ,

        /* z‑coordinate                                               */
        TRY_TO_DOUBLE( ("ImagePositionPatient"[2])::STRING )     AS pos_z ,

        "Rows"                                             AS rows_val ,
        "Columns"                                          AS cols_val ,
        TRY_TO_DOUBLE( "SliceThickness"::STRING )          AS slice_thk ,
        TRY_TO_DOUBLE( "Exposure"::STRING )                AS exposure ,
        "instance_size"                                    AS inst_size ,

        /* | dot( r×c , 0,0,1 ) |  = | r_x*c_y – r_y*c_x |            */
        ABS(
            TRY_TO_DOUBLE( ("ImageOrientationPatient"[0])::STRING ) *
            TRY_TO_DOUBLE( ("ImageOrientationPatient"[4])::STRING ) -
            TRY_TO_DOUBLE( ("ImageOrientationPatient"[1])::STRING ) *
            TRY_TO_DOUBLE( ("ImageOrientationPatient"[3])::STRING )
        )                                                  AS slice_dot
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  "Modality"               = 'CT'
      AND  LOWER("collection_id")  <> 'nlst'
      AND  "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                       '1.2.840.10008.1.2.4.51')
      AND  UPPER("ImageType"::STRING) NOT LIKE '%LOCALIZER%'
      AND  "ImageOrientationPatient" IS NOT NULL
      AND  "PixelSpacing"            IS NOT NULL
      AND  "ImagePositionPatient"    IS NOT NULL
      AND  "Rows"    IS NOT NULL
      AND  "Columns" IS NOT NULL
),
dz AS (                    /* slice spacing (Δz) per series */
    SELECT  series_uid,
            pos_z - LAG(pos_z) OVER (PARTITION BY series_uid
                                      ORDER BY pos_z) AS dz
    FROM    inst
),
dz_stats AS (              /* min/max/tolerance of Δz per series */
    SELECT  series_uid,
            MAX(dz)              AS max_dz,
            MIN(dz)              AS min_dz,
            MAX(dz)-MIN(dz)      AS tol_dz
    FROM    dz
    WHERE   dz IS NOT NULL
    GROUP BY series_uid
),
series AS (                /* aggregate & geometry checks */
    SELECT
        i.series_uid ,
        MAX(i.series_no)                         AS series_no ,
        MAX(i.study_uid)                         AS study_uid ,
        MAX(i.patient_id)                        AS patient_id ,
        MAX(i.slice_dot)                         AS max_dot ,
        MIN(i.slice_dot)                         AS min_dot ,
        COUNT(*)                                 AS sop_cnt ,
        COUNT(DISTINCT i.slice_thk)              AS n_slice_thk ,
        d.max_dz ,
        d.min_dz ,
        d.tol_dz ,
        COUNT(DISTINCT i.exposure)               AS n_expo ,
        MAX(i.exposure)                          AS max_expo ,
        MIN(i.exposure)                          AS min_expo ,
        MAX(i.exposure) - MIN(i.exposure)        AS diff_expo ,
        SUM(i.inst_size)/1048576.0               AS size_mib ,

        /* geometry consistency counters */
        COUNT(DISTINCT i.ori_str)                AS n_ori ,
        COUNT(DISTINCT i.pixsp_str)              AS n_pixsp ,
        COUNT(DISTINCT i.ipp_xy_str)             AS n_ipp_xy ,
        COUNT(DISTINCT i.ipp_full_str)           AS n_ipp_full ,
        MIN(i.rows_val)                          AS min_rows ,
        MAX(i.rows_val)                          AS max_rows ,
        MIN(i.cols_val)                          AS min_cols ,
        MAX(i.cols_val)                          AS max_cols
    FROM   inst i
           JOIN dz_stats d USING (series_uid)
    GROUP  BY i.series_uid , d.max_dz , d.min_dz , d.tol_dz
),
qualified AS (            /* keep only series passing all criteria */
    SELECT *
    FROM   series
    WHERE  n_ori     = 1
      AND  n_pixsp   = 1
      AND  n_ipp_xy  = 1
      AND  sop_cnt   = n_ipp_full
      AND  min_rows  = max_rows
      AND  min_cols  = max_cols
      AND  min_dot  >= 0.99        /* |dot| ≥ 0.99  ( 1 ± 0.01 ) */
)
SELECT
    series_uid                      AS "SeriesInstanceUID",
    series_no                       AS "SeriesNumber",
    study_uid                       AS "StudyInstanceUID",
    patient_id                      AS "PatientID",
    ROUND(max_dot,5)                AS "MaxDotProduct",
    sop_cnt                         AS "SOPInstances",
    n_slice_thk                     AS "DistinctSliceThickness",
    max_dz                          AS "MaxSliceInterval",
    min_dz                          AS "MinSliceInterval",
    tol_dz                          AS "SliceIntervalTolerance",
    n_expo                          AS "DistinctExposureValues",
    max_expo                        AS "MaxExposure",
    min_expo                        AS "MinExposure",
    diff_expo                       AS "ExposureRange",
    ROUND(size_mib,2)               AS "SeriesSizeMiB"
FROM   qualified
ORDER BY "SliceIntervalTolerance" DESC NULLS LAST,
         "ExposureRange"          DESC NULLS LAST,
         "SeriesInstanceUID"      DESC;