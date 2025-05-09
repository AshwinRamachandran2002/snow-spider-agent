WITH per_instance AS (
    /*--------------------------------------------------------------------
      Collect per–image information for CT images that meet basic filters
    --------------------------------------------------------------------*/
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID",
        "instance_size"                                               AS inst_size_bytes,
        TO_VARCHAR("ImageType")                                       AS img_type,
        "TransferSyntaxUID",
        "ImageOrientationPatient"                                     AS iop,          -- 6‑element array
        "PixelSpacing",
        "Rows",
        "Columns",
        TRY_TO_NUMBER( ("ImagePositionPatient"[2])::STRING )          AS z_pos,        -- z‑coordinate
        "XRayTubeCurrentInmA"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND "collection_id" <> 'nlst'
      AND UPPER(TO_VARCHAR("ImageType")) NOT LIKE '%LOCALIZER%'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',       -- JPEG Baseline
                                      '1.2.840.10008.1.2.4.51')       -- JPEG Lossless
),
per_series AS (
    /*--------------------------------------------------------------------
      Aggregate per series and check consistency of acquisition parameters
    --------------------------------------------------------------------*/
    SELECT
        "SeriesInstanceUID",
        MIN("SeriesNumber")                                           AS series_number,
        MIN("PatientID")                                              AS patient_id,
        SUM(inst_size_bytes)/1048576.0                                AS series_size_mib,
        COUNT(*)                                                      AS n_images,
        COUNT(DISTINCT iop)                                           AS n_iop,
        COUNT(DISTINCT "PixelSpacing")                                AS n_pix_spacing,
        COUNT(DISTINCT "Rows")                                        AS n_rows,
        COUNT(DISTINCT "Columns")                                     AS n_cols,
        COUNT(DISTINCT "XRayTubeCurrentInmA")                         AS n_xray_current,
        COUNT(DISTINCT z_pos)                                         AS n_z_pos,
        ANY_VALUE(iop)                                                AS iop_any
    FROM per_instance
    GROUP BY "SeriesInstanceUID"
),
qualified_series AS (
    /*--------------------------------------------------------------------
      Keep only series that satisfy all strict consistency requirements
    --------------------------------------------------------------------*/
    SELECT
        ps.*,
        ABS(   TRY_TO_DOUBLE(ps.iop_any[0]::STRING) * TRY_TO_DOUBLE(ps.iop_any[4]::STRING)
             - TRY_TO_DOUBLE(ps.iop_any[1]::STRING) * TRY_TO_DOUBLE(ps.iop_any[3]::STRING)
        ) AS cross_z
    FROM per_series ps
    WHERE
          ps.n_iop          = 1   -- single image orientation
      AND ps.n_pix_spacing   = 1   -- constant pixel spacing
      AND ps.n_rows          = 1   -- constant rows
      AND ps.n_cols          = 1   -- constant columns
      AND ps.n_xray_current <= 1   -- constant exposure
      AND ps.n_z_pos         = ps.n_images  -- one image per z‑position
      AND ABS(   TRY_TO_DOUBLE(ps.iop_any[0]::STRING) * TRY_TO_DOUBLE(ps.iop_any[4]::STRING)
               - TRY_TO_DOUBLE(ps.iop_any[1]::STRING) * TRY_TO_DOUBLE(ps.iop_any[3]::STRING)
          ) BETWEEN 0.99 AND 1.01         -- axial (or strictly aligned) orientation
)
SELECT
    "SeriesInstanceUID",
    series_number                     AS "SeriesNumber",
    patient_id                        AS "PatientID",
    ROUND(series_size_mib, 2)         AS "SeriesSize_MiB"
FROM qualified_series
ORDER BY series_size_mib DESC NULLS LAST
LIMIT 5;