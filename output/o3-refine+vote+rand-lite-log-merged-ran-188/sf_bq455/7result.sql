/*  Top 5 largest, good-quality axial CT series (non-NLST, non-JPEG, non-LOCALIZER)  */
WITH series_stats AS (          -- aggregate once per series
    SELECT
        "SeriesInstanceUID",
        MIN("SeriesNumber")                          AS "SeriesNumber",
        MIN("PatientID")                             AS "PatientID",
        SUM("instance_size")/1048576.0               AS "SeriesSize_MB",
        COUNT(*)                                     AS n_images,
        COUNT(DISTINCT ("ImagePositionPatient"[2]::FLOAT))        AS n_z,
        COUNT(DISTINCT "ImageOrientationPatient")    AS n_orient,
        ANY_VALUE("ImageOrientationPatient")         AS iop,      -- single orientation kept
        COUNT(DISTINCT ("PixelSpacing"[0]::FLOAT))   AS n_ps0,
        COUNT(DISTINCT ("PixelSpacing"[1]::FLOAT))   AS n_ps1,
        COUNT(DISTINCT "Rows")                       AS n_rows,
        COUNT(DISTINCT "Columns")                    AS n_cols,
        COUNT(DISTINCT "ExposureInmAs")              AS n_exposure
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  "Modality" = 'CT'
      AND  "collection_id" <> 'nlst'
      AND  ("ImageType" IS NULL OR "ImageType" NOT ILIKE '%LOCALIZER%')
      AND  "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',   -- JPEG Lossless
                                       '1.2.840.10008.1.2.4.51')   -- JPEG Baseline/Extended
    GROUP  BY "SeriesInstanceUID"
),
series_filtered AS (            -- apply consistency rules
    SELECT
        *,
        iop[0]::FLOAT AS r1,  iop[1]::FLOAT AS r2,  iop[2]::FLOAT AS r3,
        iop[3]::FLOAT AS c1,  iop[4]::FLOAT AS c2,  iop[5]::FLOAT AS c3
    FROM   series_stats
    WHERE  n_orient = 1                    -- one unique orientation
      AND  n_images = n_z                  -- no duplicate z slices
      AND  n_ps0 <= 1 AND n_ps1 <= 1       -- constant pixel spacing
      AND  n_rows  = 1 AND n_cols = 1      -- constant matrix size
      AND  n_exposure <= 1                 -- constant exposure (if present)
),
axial_ok AS (                   -- keep only axial (|normal_z| ≈ 1)
    SELECT
        *,
        ABS(r1*c2 - r2*c1) AS normal_z
    FROM   series_filtered
    WHERE  ABS(r1*c2 - r2*c1) BETWEEN 0.99 AND 1.01
)
SELECT
    "SeriesInstanceUID",
    "SeriesNumber",
    "PatientID",
    ROUND("SeriesSize_MB",3) AS "SeriesSize_MB"
FROM   axial_ok
ORDER  BY "SeriesSize_MB" DESC NULLS LAST
LIMIT  5;