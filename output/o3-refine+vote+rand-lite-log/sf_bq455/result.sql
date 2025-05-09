/*  Top‑5 largest CT series (MiB) that satisfy the requested quality criteria            */

WITH per_instance AS (          -- 1. pre‑filter instances
    SELECT
        "SeriesInstanceUID",
        "PatientID",
        "SeriesNumber",
        "instance_size",
        "ImageType",
        "TransferSyntaxUID",
        "ImageOrientationPatient",
        "ImagePositionPatient",
        "PixelSpacing",
        "Rows",
        "Columns",
        "ExposureInmAs",
        "SliceThickness"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE  "Modality" = 'CT'                     -- CT only
      AND  LOWER("collection_id") <> 'nlst'      -- exclude NLST collection
),

series_qc AS (               -- 2. aggregate by series & calculate QC metrics
    SELECT
        "SeriesInstanceUID",
        MIN("PatientID")                       AS patient_id,
        MIN("SeriesNumber")                    AS series_number,
        SUM("instance_size")                   AS bytes_tot,
        COUNT(*)                               AS img_cnt,
        /* distinct‑ness counts (must all equal 1)                                      */
        COUNT(DISTINCT "ImageOrientationPatient")              AS n_orient,
        COUNT(DISTINCT "PixelSpacing")                         AS n_pxsp,
        COUNT(DISTINCT "Rows")                                 AS n_rows,
        COUNT(DISTINCT "Columns")                              AS n_cols,
        COUNT(DISTINCT "ExposureInmAs")                        AS n_exposure,
        COUNT(DISTINCT "SliceThickness")                       AS n_thick,
        /* xy position constancy                                                        */
        COUNT(DISTINCT
              TO_VARCHAR(ROUND(("ImagePositionPatient")[0]::FLOAT,5))
              ||','||
              TO_VARCHAR(ROUND(("ImagePositionPatient")[1]::FLOAT,5))
        )                                                      AS n_xy_pos,
        /* unique z positions                                                           */
        COUNT(DISTINCT ROUND(("ImagePositionPatient")[2]::FLOAT,5)) AS n_z_pos,
        /* flags for disqualifiers                                                      */
        MAX( IFF( UPPER("ImageType")     LIKE '%LOCALIZER%' , 1 , 0) )    AS has_localizer,
        MAX( IFF( "TransferSyntaxUID" IN ('1.2.840.10008.1.2.4.70',
                                          '1.2.840.10008.1.2.4.51'), 1, 0) ) AS has_jpeg,
        /* components to compute z‑axis of cross product                                */
        MIN( ("ImageOrientationPatient")[0]::FLOAT )           AS dir_x1,
        MIN( ("ImageOrientationPatient")[1]::FLOAT )           AS dir_x2,
        MIN( ("ImageOrientationPatient")[3]::FLOAT )           AS dir_y1,
        MIN( ("ImageOrientationPatient")[4]::FLOAT )           AS dir_y2
    FROM  per_instance
    GROUP BY "SeriesInstanceUID"
),

series_filtered AS (         -- 3. apply QC constraints
    SELECT
        "SeriesInstanceUID",
        patient_id,
        series_number,
        bytes_tot,
        /* size in MiB */
        bytes_tot / 1048576.0  AS size_mib
    FROM series_qc
    WHERE  has_localizer = 0                -- no LOCALIZER images
       AND has_jpeg      = 0                -- no JPEG‑compressed TS
       /* quality consistency checks (all must be 1) */
       AND n_orient   = 1
       AND n_pxsp     = 1
       AND n_rows     = 1
       AND n_cols     = 1
       AND n_exposure <= 1                  -- allow NULL or single value
       AND n_thick    = 1
       AND n_xy_pos   = 1
       /* one image per unique z position (i.e., no duplicate slices) */
       AND img_cnt = n_z_pos
       /* imaging plane alignment: |x×y|_z between 0.99 and 1.01       */
       AND ABS( dir_x1 * dir_y2 - dir_x2 * dir_y1 ) BETWEEN 0.99 AND 1.01
)

SELECT
    "SeriesInstanceUID"          AS series_uid,
    series_number,
    patient_id,
    ROUND(size_mib,2)            AS series_size_mib
FROM   series_filtered
ORDER  BY series_size_mib DESC
LIMIT  5;