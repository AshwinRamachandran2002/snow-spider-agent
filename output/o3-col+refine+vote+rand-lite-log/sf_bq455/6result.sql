WITH filtered AS (          /* keep CT instances that satisfy basic per-image criteria */
    SELECT
        "SeriesInstanceUID",
        "PatientID",
        "SeriesNumber",
        "ImageOrientationPatient"                        AS iop,          /* VARIANT[6] */
        "PixelSpacing",
        "Rows",
        "Columns",
        TRY_TO_DOUBLE( "ImagePositionPatient"[2]::string )  AS zpos,      /* z-coordinate */
        "ExposureInmAs",
        "instance_size"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND "collection_id" <> 'nlst'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                      '1.2.840.10008.1.2.4.51')          /* exclude JPEG */
      AND ( "ImageType" IS NULL
            OR NOT ( "ImageType"::string ILIKE '%LOCALIZER%' ) )         /* exclude localizers */
      AND "ImagePositionPatient" IS NOT NULL
      AND ARRAY_SIZE("ImageOrientationPatient") = 6                      /* orientation present */
),

series_stats AS (          /* derive series-level statistics and consistency checks */
    SELECT
        "SeriesInstanceUID",
        MIN("SeriesNumber")                            AS "SeriesNumber",
        MIN("PatientID")                               AS "PatientID",
        COUNT(*)                                       AS n_images,
        COUNT(DISTINCT zpos)                           AS n_unique_z,
        COUNT(DISTINCT iop)                            AS n_iop,
        COUNT(DISTINCT "PixelSpacing")                 AS n_pixspacing,
        COUNT(DISTINCT "Rows")                         AS n_rows,
        COUNT(DISTINCT "Columns")                      AS n_cols,
        COUNT(DISTINCT "ExposureInmAs")                AS n_exposure,          /* NULLs ignored */
        SUM("instance_size")/1048576.0                 AS series_size_mib,
        /* absolute z-component of cross-product of row & column direction cosines */
        ABS(
               MIN( TRY_TO_DOUBLE(iop[0]::string) ) * MIN( TRY_TO_DOUBLE(iop[4]::string) )
             - MIN( TRY_TO_DOUBLE(iop[1]::string) ) * MIN( TRY_TO_DOUBLE(iop[3]::string) )
        )                                              AS z_dir_abs
    FROM filtered
    GROUP BY "SeriesInstanceUID"
),

qualified AS (            /* retain only series that pass all consistency filters */
    SELECT *
    FROM series_stats
    WHERE n_images  = n_unique_z              /* no duplicate slices */
      AND n_iop     = 1                       /* single orientation */
      AND n_pixspacing = 1                    /* constant pixel spacing */
      AND n_rows       = 1                    /* constant rows */
      AND n_cols       = 1                    /* constant columns */
      AND (n_exposure = 0 OR n_exposure = 1)  /* consistent exposure if present */
      AND z_dir_abs BETWEEN 0.99 AND 1.01     /* axial (or near-axial) orientation */
)

SELECT
    "SeriesInstanceUID",
    "SeriesNumber",
    "PatientID",
    ROUND(series_size_mib, 2) AS series_size_mib
FROM qualified
ORDER BY series_size_mib DESC NULLS LAST
LIMIT 5;