/*  Top-5 largest CT series (MiB) that pass the requested consistency criteria        */
WITH filtered AS (   ----------------------------------------------------------------
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID",
        "instance_size",
        ("ImagePositionPatient"::VARIANT)[0]::FLOAT AS pos_x,
        ("ImagePositionPatient"::VARIANT)[1]::FLOAT AS pos_y,
        ("ImagePositionPatient"::VARIANT)[2]::FLOAT AS pos_z,
        "ImageOrientationPatient",
        "PixelSpacing",
        "Rows",
        "Columns",
        "XRayTubeCurrentInmA",
        "TransferSyntaxUID"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND "collection_id" <> 'nlst'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',    -- JPEG-LS / lossy
                                      '1.2.840.10008.1.2.4.51')    -- lossy JPEG
      AND "ImageType" NOT ILIKE '%LOCALIZER%'                      -- exclude localisers
),
series_summary AS ( --------------------------------------------------------------
    SELECT
        "SeriesInstanceUID",
        MAX("SeriesNumber")            AS SeriesNumber,
        MAX("PatientID")               AS PatientID,
        SUM("instance_size")/1048576.0 AS series_size_mib,
        COUNT(*)                       AS n_images,
        COUNT(DISTINCT pos_z)          AS n_unique_z,
        COUNT(DISTINCT TO_VARCHAR(pos_x)||'_'||TO_VARCHAR(pos_y)) AS n_xy_pairs,
        COUNT(DISTINCT "ImageOrientationPatient") AS n_orient,
        COUNT(DISTINCT "PixelSpacing")            AS n_pixsp,
        COUNT(DISTINCT "Rows")                    AS n_rows,
        COUNT(DISTINCT "Columns")                 AS n_cols,
        COUNT(DISTINCT "XRayTubeCurrentInmA")     AS n_tube_current
    FROM filtered
    GROUP BY "SeriesInstanceUID"
),
spacing_consistency AS ( ---------------------------------------------------------
    SELECT
        "SeriesInstanceUID",
        COUNT(DISTINCT ROUND(spacing,6)) AS n_spacings
    FROM (
        SELECT
            "SeriesInstanceUID",
            ABS(pos_z -
                LAG(pos_z) OVER (PARTITION BY "SeriesInstanceUID" ORDER BY pos_z)
            ) AS spacing
        FROM filtered
    ) tmp
    WHERE spacing IS NOT NULL
    GROUP BY "SeriesInstanceUID"
),
orientation_value AS ( ----------------------------------------------------------
    SELECT
        "SeriesInstanceUID",
        ABS( (ori[0]::FLOAT * ori[4]::FLOAT) -
             (ori[1]::FLOAT * ori[3]::FLOAT) ) AS abs_z_cross
    FROM (
        SELECT DISTINCT
               "SeriesInstanceUID",
               PARSE_JSON("ImageOrientationPatient") AS ori
        FROM filtered
    )
)
/*  Final selection ------------------------------------------------------------- */
SELECT
    ss."SeriesInstanceUID",
    ss.SeriesNumber,
    ss.PatientID,
    ROUND(ss.series_size_mib,2) AS series_size_mib
FROM  series_summary ss
JOIN  spacing_consistency sc ON sc."SeriesInstanceUID" = ss."SeriesInstanceUID"
JOIN  orientation_value  ov ON ov."SeriesInstanceUID" = ss."SeriesInstanceUID"
WHERE
      ss.n_images       = ss.n_unique_z             -- no duplicate z slices
  AND ss.n_xy_pairs     <= 1                        -- constant in-plane origin
  AND ss.n_orient       <= 1                        -- single orientation
  AND ss.n_pixsp        <= 1                        -- constant pixel spacing
  AND ss.n_rows         <= 1                        -- constant rows
  AND ss.n_cols         <= 1                        -- constant columns
  AND ss.n_tube_current <= 1                        -- constant (or null) exposure
  AND sc.n_spacings     <= 1                        -- constant slice interval
  AND ov.abs_z_cross BETWEEN 0.99 AND 1.01          -- expected imaging plane
ORDER BY
    ss.series_size_mib DESC NULLS LAST
LIMIT 5;