WITH per_instance AS (
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID",
        "instance_size"                                        AS inst_bytes,
        "ImageType",
        "TransferSyntaxUID",
        "ImageOrientationPatient",
        "PixelSpacing",
        "Rows",
        "Columns",
        "ImagePositionPatient"
    FROM  IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND LOWER("collection_id") <> 'nlst'                                         -- exclude NLST
      AND ( "ImageType" IS NULL OR "ImageType"::STRING NOT ILIKE '%LOCALIZER%' )   -- exclude LOCALIZER
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',                    -- exclude JPEG-2000
                                      '1.2.840.10008.1.2.4.51')                    -- exclude JPEG baseline
),
series_checks AS (
    SELECT
        "SeriesInstanceUID",
        MAX("SeriesNumber")                                      AS "SeriesNumber",
        MAX("PatientID")                                         AS "PatientID",
        SUM(inst_bytes)/(1024*1024)                              AS series_size_mb,   -- MiB
        COUNT(DISTINCT "ImageOrientationPatient")                AS n_orient,
        COUNT(DISTINCT "PixelSpacing")                           AS n_pxspace,
        COUNT(DISTINCT "Rows")                                   AS n_rows,
        COUNT(DISTINCT "Columns")                                AS n_cols,
        COUNT(*)                                                 AS n_imgs,
        COUNT(DISTINCT "ImagePositionPatient")                   AS n_pos
    FROM per_instance
    GROUP BY "SeriesInstanceUID"
),
good_series AS (
    SELECT *
    FROM series_checks
    WHERE n_orient = 1                    -- single orientation
      AND n_pxspace = 1                   -- single pixel spacing
      AND n_rows   = 1                    -- uniform rows
      AND n_cols   = 1                    -- uniform columns
      AND n_imgs   = n_pos               -- no duplicate slices
)
SELECT
    "SeriesInstanceUID",
    "SeriesNumber",
    "PatientID",
    ROUND(series_size_mb,2) AS series_size_MiB
FROM good_series
ORDER BY series_size_mb DESC NULLS LAST
LIMIT 5;