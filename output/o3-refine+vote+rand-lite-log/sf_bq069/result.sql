/* -------------------------------------------------------------
   CT series quality‑controlled report – IDC.V17  (Snowflake SQL)
   -------------------------------------------------------------
*/
WITH filtered AS (        /* Modality / collection / syntax / localizer filters */
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "StudyInstanceUID",
        "PatientID",
        "ImageOrientationPatient",
        "PixelSpacing",
        "Rows",
        "Columns",
        "ImagePositionPatient",
        "SliceThickness",
        "Exposure",
        "TransferSyntaxUID",
        "ImageType",
        "collection_id",
        "BlobStorageSize"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality"      = 'CT'
      AND "collection_id" <> 'nlst'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',   -- JPEG Lossless
                                      '1.2.840.10008.1.2.4.51')   -- JPEG Baseline
      /* ImageType is a VARIANT array; its string representation must not mention LOCALIZER */
      AND TO_VARCHAR("ImageType") NOT ILIKE '%LOCALIZER%'
),
orient AS (               /* unpack orientation/position & dot‑product |(row×col)·k| */
    SELECT
        f.*,
        TO_DOUBLE( GET("ImageOrientationPatient",0) ) AS xr,
        TO_DOUBLE( GET("ImageOrientationPatient",1) ) AS yr,
        TO_DOUBLE( GET("ImageOrientationPatient",2) ) AS zr,
        TO_DOUBLE( GET("ImageOrientationPatient",3) ) AS xc,
        TO_DOUBLE( GET("ImageOrientationPatient",4) ) AS yc,
        TO_DOUBLE( GET("ImageOrientationPatient",5) ) AS zc,
        TO_DOUBLE( GET("ImagePositionPatient",0)  )  AS xpos,
        TO_DOUBLE( GET("ImagePositionPatient",1)  )  AS ypos,
        TO_DOUBLE( GET("ImagePositionPatient",2)  )  AS zpos,
        ABS( (xr*yc) - (yr*xc) )                      AS dot_nz          -- z‑component
    FROM filtered f
),
deltas AS (               /* Δz between consecutive slices within each series */
    SELECT
        o.*,
        ABS( zpos - LAG(zpos) OVER (PARTITION BY "SeriesInstanceUID"
                                    ORDER BY zpos) ) AS dz
    FROM orient o
),
series AS (               /* aggregate & gather quality‑check counts           */
    SELECT
        "SeriesInstanceUID",
        MAX("SeriesNumber")                        AS "SeriesNumber",
        MAX("StudyInstanceUID")                    AS "StudyInstanceUID",
        MAX("PatientID")                           AS "PatientID",
        MAX(dot_nz)                                AS max_dot_product,
        COUNT(*)                                   AS sop_instances,
        COUNT(DISTINCT TO_VARCHAR("SliceThickness"))              AS distinct_slice_thk,
        MAX(dz)                                    AS max_dz,
        MIN(dz)                                    AS min_dz,
        MAX(dz) - MIN(dz)                          AS dz_tolerance,
        COUNT(DISTINCT "Exposure")                 AS distinct_exposure,
        MAX(TO_DOUBLE("Exposure"))                 AS max_exposure,
        MIN(TO_DOUBLE("Exposure"))                 AS min_exposure,
        MAX(TO_DOUBLE("Exposure"))-MIN(TO_DOUBLE("Exposure"))     AS exposure_range,
        SUM("BlobStorageSize")/1024/1024           AS size_mib,
        /* quality‑control helper counts */
        COUNT(DISTINCT TO_VARCHAR("ImageOrientationPatient"))     AS n_orient,
        COUNT(DISTINCT TO_VARCHAR("PixelSpacing"))                AS n_pixsp,
        COUNT(DISTINCT "Rows")                                    AS n_rows,
        COUNT(DISTINCT "Columns")                                 AS n_cols,
        COUNT(DISTINCT TO_VARCHAR(ARRAY_CONSTRUCT(xpos,ypos)))    AS n_xy,
        COUNT(DISTINCT TO_VARCHAR("ImagePositionPatient"))        AS n_pos
    FROM deltas
    GROUP BY "SeriesInstanceUID"
),
qualified AS (            /* enforce all geometry & consistency requirements   */
    SELECT *
    FROM   series
    WHERE  n_orient = 1
      AND  n_pixsp  = 1
      AND  n_rows   = 1
      AND  n_cols   = 1
      AND  n_xy     = 1
      AND  sop_instances = n_pos
      AND  max_dot_product BETWEEN 0.99 AND 1.01
)
SELECT
    "SeriesInstanceUID",
    "SeriesNumber",
    "StudyInstanceUID",
    "PatientID",
    max_dot_product                       AS "MaxDotProduct",
    sop_instances                         AS "SOPInstances",
    distinct_slice_thk                    AS "DistinctSliceThickness",
    max_dz                                AS "MaxSliceIntervalDiff",
    min_dz                                AS "MinSliceIntervalDiff",
    dz_tolerance                          AS "SliceIntervalTolerance",
    distinct_exposure                     AS "DistinctExposureValues",
    max_exposure                          AS "MaxExposure",
    min_exposure                          AS "MinExposure",
    exposure_range                        AS "ExposureRange",
    ROUND(size_mib,2)                     AS "SeriesSize_MiB"
FROM qualified
ORDER BY
    dz_tolerance      DESC NULLS LAST,
    exposure_range    DESC NULLS LAST,
    "SeriesInstanceUID" DESC;