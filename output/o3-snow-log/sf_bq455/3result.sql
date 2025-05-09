/* --------------------  TOP-5 LARGEST, QC-PASSED CT SERIES  ------------------- */

WITH raw_ct AS (                       /* candidate CT images, non-NLST, non-JPEG */
    SELECT
        "SeriesInstanceUID",
        "SOPInstanceUID",
        "SeriesNumber",
        "PatientID",
        "instance_size",                               -- bytes
        "ImageOrientationPatient"        AS iop,       -- VARIANT[6]
        "ImagePositionPatient"           AS ipp,       -- VARIANT[3]
        TO_DOUBLE("ImagePositionPatient"[0]) AS x_pos,
        TO_DOUBLE("ImagePositionPatient"[1]) AS y_pos,
        TO_DOUBLE("ImagePositionPatient"[2]) AS z_pos,
        TO_VARCHAR("PixelSpacing")           AS pix_sp,
        "Rows"                              AS n_rows,
        "Columns"                           AS n_cols,
        "ExposureInmAs"                     AS exp_mas,
        "ImageType"                         AS img_type
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND "collection_id" <> 'nlst'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                      '1.2.840.10008.1.2.4.51')
      -- exclude LOCALIZER images
      AND ( "ImageType" IS NULL
            OR POSITION('LOCALIZER'
                        IN UPPER(TO_VARCHAR("ImageType"))) = 0 )
), /* ------------------------------------------------------------------------ */

dz AS (                                /* slice-to-slice Z-spacing per series */
    SELECT
        "SeriesInstanceUID",
        ABS( z_pos - LAG(z_pos) OVER (PARTITION BY "SeriesInstanceUID"
                                      ORDER BY z_pos) )   AS dz
    FROM raw_ct
), /* ------------------------------------------------------------------------ */

series_qc AS (                          /* quality-control aggregates */
    SELECT
        r."SeriesInstanceUID",
        MAX(r."SeriesNumber")                            AS series_number,
        MAX(r."PatientID")                               AS patient_id,
        SUM(r."instance_size") / 1024 / 1024             AS size_mib,
        COUNT(*)                                         AS n_images,
        COUNT(DISTINCT r.z_pos)                          AS n_z,
        COUNT(DISTINCT TO_VARCHAR(r.iop))                AS n_iop,
        COUNT(DISTINCT r.pix_sp)                         AS n_pix,
        COUNT(DISTINCT r.n_rows)                         AS n_rows,
        COUNT(DISTINCT r.n_cols)                         AS n_cols,
        COUNT(DISTINCT r.exp_mas)                        AS n_exp,
        COALESCE(MIN(d.dz),0)                            AS min_dz,
        COALESCE(MAX(d.dz),0)                            AS max_dz,
        /* |z| component of  (X_dir  ×  Y_dir)  from IOP */
        ABS( MIN(TO_DOUBLE(r.iop[0])) * MIN(TO_DOUBLE(r.iop[4]))
           - MIN(TO_DOUBLE(r.iop[1])) * MIN(TO_DOUBLE(r.iop[3])) ) AS nz_abs
    FROM raw_ct r
    LEFT JOIN dz d
           ON r."SeriesInstanceUID" = d."SeriesInstanceUID"
    GROUP BY r."SeriesInstanceUID"
), /* ------------------------------------------------------------------------ */

passed AS (                             /* apply all requested QC requirements */
    SELECT *
    FROM   series_qc
    WHERE  n_images          = n_z          -- one image per z-slice
       AND n_iop             = 1            -- single orientation
       AND n_pix             = 1            -- constant pixel spacing
       AND n_rows            = 1            -- constant rows
       AND n_cols            = 1            -- constant columns
       AND n_exp            <= 1            -- constant exposure (or all NULL)
       AND (max_dz - min_dz) < 0.1          -- uniform slice spacing (≤0.1 mm)
       AND nz_abs BETWEEN 0.9 AND 1.1       -- imaging plane alignment
)

SELECT
    "SeriesInstanceUID",
    series_number,
    patient_id,
    ROUND(size_mib,2) AS series_size_mib
FROM   passed
ORDER  BY series_size_mib DESC NULLS LAST
LIMIT 5;