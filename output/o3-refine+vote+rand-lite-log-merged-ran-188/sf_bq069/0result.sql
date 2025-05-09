WITH inst AS (   /*---  pick CT instances that satisfy the basic exclusion rules ----------------*/
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "StudyInstanceUID",
        "PatientID",
        "ImageOrientationPatient",
        "ImagePositionPatient",
        "PixelSpacing",
        "Rows",
        "Columns",
        "SliceThickness",
        "ExposureInmAs",
        "instance_size",
        /*---- compute the absolute dot product of row×col with the Z‑axis ----------------------*/
        ABS( ( "ImageOrientationPatient"[0]::FLOAT * "ImageOrientationPatient"[4]::FLOAT )
            - ( "ImageOrientationPatient"[1]::FLOAT * "ImageOrientationPatient"[3]::FLOAT ) )  AS "abs_dot"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE  "Modality" = 'CT'
           /* exclude NLST */
      AND  UPPER("collection_name") <> 'NLST'
      AND  UPPER("collection_id")   <> 'NLST'
           /* exclude JPEG‑compressed transfer syntaxes */
      AND  "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                       '1.2.840.10008.1.2.4.51')
           /* exclude localizer series */
      AND  UPPER( CAST("ImageType" AS STRING) ) NOT LIKE '%LOCALIZER%'
)
, geom_checks AS (   /*----  series–level tests that every instance must pass -------------------*/
    SELECT
        "SeriesInstanceUID"                                                    AS series_uid,
        MAX("SeriesNumber")                                                    AS series_number,
        MAX("StudyInstanceUID")                                                AS study_uid,
        MAX("PatientID")                                                       AS patient_id,
        COUNT(*)                                                               AS inst_cnt,
        COUNT(DISTINCT CAST("ImageOrientationPatient" AS STRING))              AS n_orient,
        COUNT(DISTINCT CAST("PixelSpacing"            AS STRING))              AS n_pixspc,
        COUNT(DISTINCT CAST("ImagePositionPatient"    AS STRING))              AS n_pos,
        COUNT(DISTINCT CAST(ARRAY_CONSTRUCT(
                                   "ImagePositionPatient"[0],
                                   "ImagePositionPatient"[1]) AS STRING))      AS n_xy,
        COUNT(DISTINCT "Rows")                                                 AS n_rows,
        COUNT(DISTINCT "Columns")                                              AS n_cols,
        MIN("abs_dot")                                                         AS min_abs_dot,
        MAX("abs_dot")                                                         AS max_abs_dot,
        COUNT(DISTINCT CAST("SliceThickness" AS STRING))                       AS n_slice_thk,
        COUNT(DISTINCT "ExposureInmAs")                                        AS n_exposure,
        MAX("ExposureInmAs")                                                   AS max_exposure,
        MIN("ExposureInmAs")                                                   AS min_exposure,
        SUM("instance_size")                                                   AS size_bytes
    FROM inst
    GROUP BY "SeriesInstanceUID"
    HAVING      n_orient   = 1
            AND n_pixspc   = 1
            AND n_rows     = 1
            AND n_cols     = 1
            AND n_pos      = inst_cnt               /* every slice unique           */
            AND n_xy       = 1                      /* XY of ImagePosition identical*/
            AND min_abs_dot >= 0.99
            AND max_abs_dot <= 1.01
)
, z_sorted AS (   /*----  z–positions and inter‑slice spacing ----------------------------------*/
    SELECT
        i."SeriesInstanceUID"                    AS series_uid,
        "ImagePositionPatient"[2]::FLOAT         AS z,
        ROW_NUMBER() OVER (PARTITION BY i."SeriesInstanceUID"
                           ORDER BY "ImagePositionPatient"[2]::FLOAT) AS rn
    FROM inst i
    INNER JOIN geom_checks g
            ON i."SeriesInstanceUID" = g.series_uid
)
, dz AS (
    SELECT
        series_uid,
        ABS( z - LAG(z) OVER (PARTITION BY series_uid ORDER BY rn) ) AS dz
    FROM z_sorted
)
, dz_aggr AS (
    SELECT
        series_uid,
        MAX(dz) AS max_dz,
        MIN(dz) AS min_dz,
        MAX(dz) - MIN(dz) AS tol_dz
    FROM dz
    WHERE dz IS NOT NULL
    GROUP BY series_uid
)
SELECT
    g.series_uid                                           AS "SeriesInstanceUID",
    g.series_number                                        AS "SeriesNumber",
    g.study_uid                                            AS "StudyInstanceUID",
    g.patient_id                                           AS "PatientID",
    g.max_abs_dot                                          AS "MaxDotProduct",
    g.inst_cnt                                             AS "NumInstances",
    g.n_slice_thk                                          AS "DistinctSliceThicknesses",
    dz.max_dz                                              AS "MaxSliceΔ",
    dz.min_dz                                              AS "MinSliceΔ",
    dz.tol_dz                                              AS "SliceΔTolerance",
    g.n_exposure                                           AS "DistinctExposureValues",
    g.max_exposure                                         AS "MaxExposure_mAs",
    g.min_exposure                                         AS "MinExposure_mAs",
    (g.max_exposure - g.min_exposure)                      AS "ExposureRange_mAs",
    ROUND( g.size_bytes / 1048576 , 3)                     AS "SeriesSize_MiB"
FROM geom_checks g
LEFT JOIN dz_aggr dz
       ON g.series_uid = dz.series_uid
ORDER BY
      dz.tol_dz           DESC NULLS LAST,
      (g.max_exposure - g.min_exposure) DESC NULLS LAST,
      g.series_uid        DESC;