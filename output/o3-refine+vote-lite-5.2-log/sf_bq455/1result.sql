WITH series_stats AS ( 
    SELECT
        "SeriesInstanceUID",
        MIN("SeriesNumber")                                AS "SeriesNumber",
        MIN("PatientID")                                   AS "PatientID",
        SUM("instance_size") / (1024*1024)                 AS "SeriesSizeMiB",   -- MiB
        COUNT(*)                                           AS img_cnt,
        COUNT(DISTINCT ("ImagePositionPatient"[2]::string))AS z_cnt,             -- unique z‐positions
        COUNT(DISTINCT "ImageOrientationPatient")          AS orient_cnt,
        COUNT(DISTINCT "PixelSpacing")                     AS pxspace_cnt,
        COUNT(DISTINCT "Rows")                             AS row_cnt,
        COUNT(DISTINCT "Columns")                          AS col_cnt,
        COUNT(DISTINCT "XRayTubeCurrentInmA")              AS exp_cnt,
        COUNT(DISTINCT "SpacingBetweenSlices")             AS slice_intvl_cnt,
        MIN(("ImageOrientationPatient"[0])::float)         AS row_x,
        MIN(("ImageOrientationPatient"[1])::float)         AS row_y,
        MIN(("ImageOrientationPatient"[3])::float)         AS col_x,
        MIN(("ImageOrientationPatient"[4])::float)         AS col_y
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  "Modality" = 'CT'
      AND  "collection_id" <> 'nlst'
      AND  ( "TransferSyntaxUID" IS NULL 
             OR "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                             '1.2.840.10008.1.2.4.51') )
      AND  ( "ImageType" IS NULL 
             OR POSITION('LOCALIZER' IN UPPER(ARRAY_TO_STRING("ImageType",','))) = 0 )
    GROUP BY "SeriesInstanceUID"
    HAVING img_cnt              = z_cnt          -- no duplicate slices
       AND orient_cnt           = 1              -- single orientation
       AND pxspace_cnt          = 1              -- constant pixel spacing
       AND row_cnt              = 1              -- constant rows
       AND col_cnt              = 1              -- constant columns
       AND exp_cnt             <= 1              -- constant exposure (if present)
       AND slice_intvl_cnt     <= 1              -- uniform slice interval (if recorded)
), oriented AS (
    SELECT
        *,
        ABS(row_x*col_y - row_y*col_x)            AS cross_z_abs          -- z component of cross‑product
    FROM   series_stats
    WHERE  ABS(row_x*col_y - row_y*col_x) BETWEEN 0.99 AND 1.01           -- axial/near‑axial
)
SELECT
    "SeriesInstanceUID",
    "SeriesNumber",
    "PatientID",
    "SeriesSizeMiB"
FROM   oriented
ORDER  BY "SeriesSizeMiB" DESC NULLS LAST
LIMIT  5;