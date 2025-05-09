WITH per_series AS (
    SELECT
        "SeriesInstanceUID",
        MIN("SeriesNumber")                                                AS "SeriesNumber",
        MIN("PatientID")                                                   AS "PatientID",
        COUNT(*)                                                           AS img_cnt,
        COUNT(DISTINCT ("ImagePositionPatient"[2])::FLOAT)                 AS uniq_z,
        COUNT(DISTINCT "PixelSpacing")                                     AS uniq_pxsp,
        COUNT(DISTINCT "ImageOrientationPatient")                          AS uniq_orient,
        COUNT(DISTINCT "XRayTubeCurrent")                                  AS uniq_curr,
        COUNT(DISTINCT "Rows")                                             AS uniq_rows,
        COUNT(DISTINCT "Columns")                                          AS uniq_cols,
        MAX(ABS(                                                           -- |Z| component of cross-product
              ("ImageOrientationPatient"[0])::FLOAT *
              ("ImageOrientationPatient"[4])::FLOAT -
              ("ImageOrientationPatient"[1])::FLOAT *
              ("ImageOrientationPatient"[3])::FLOAT ))                    AS z_cross_abs,
        ROUND(SUM("instance_size") / 1048576 , 2)                          AS series_size_MiB
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'                                   -- CT only
      AND "collection_id" <> 'nlst'                           -- exclude NLST
      AND ( "ImageType" IS NULL OR
            "ImageType" NOT ILIKE '%LOCALIZER%' )             -- drop localizers
      AND "TransferSyntaxUID" NOT IN (                        -- drop JPEG-compressed
            '1.2.840.10008.1.2.4.70',
            '1.2.840.10008.1.2.4.51')
    GROUP BY "SeriesInstanceUID"
)
SELECT
    "SeriesInstanceUID",
    "SeriesNumber",
    "PatientID",
    series_size_MiB
FROM per_series
WHERE img_cnt      = uniq_z        -- no duplicate slices
  AND uniq_pxsp    = 1             -- one pixel spacing
  AND uniq_orient  = 1             -- one orientation
  AND uniq_curr    = 1             -- one exposure (tube current)
  AND uniq_rows    = 1             -- fixed rows
  AND uniq_cols    = 1             -- fixed columns
  AND z_cross_abs BETWEEN 0.99 AND 1.01   -- axial/sagittal/coronal plane check
ORDER BY series_size_MiB DESC NULLS LAST
LIMIT 5;