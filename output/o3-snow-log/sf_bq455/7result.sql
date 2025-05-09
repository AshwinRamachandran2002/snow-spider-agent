WITH inst AS (   /* CT instances outside NLST with basic image-level filters */
    SELECT
        "SOPInstanceUID",
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID",
        "instance_size",
        "ImageType",
        "TransferSyntaxUID",
        "ImageOrientationPatient",
        "ImagePositionPatient",
        TRY_TO_DOUBLE( "ImagePositionPatient"[2]::STRING )           AS z_position,
        TO_VARCHAR("PixelSpacing")                                   AS pix_space,
        "Rows",
        "Columns"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND "collection_id" <> 'nlst'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                      '1.2.840.10008.1.2.4.51')
      AND ( "ImageType" IS NULL
            OR UPPER(TO_VARCHAR("ImageType")) NOT LIKE '%LOCALIZER%' )
),
/* orientation values (one row per series) */
orientation AS (
    SELECT
        "SeriesInstanceUID",
        MIN(TRY_TO_DOUBLE(("ImageOrientationPatient"[0])::STRING)) AS rx,
        MIN(TRY_TO_DOUBLE(("ImageOrientationPatient"[1])::STRING)) AS ry,
        MIN(TRY_TO_DOUBLE(("ImageOrientationPatient"[3])::STRING)) AS cx,
        MIN(TRY_TO_DOUBLE(("ImageOrientationPatient"[4])::STRING)) AS cy
    FROM inst
    GROUP BY "SeriesInstanceUID"
),
/* counts for per-series consistency checks */
orientation_cnt AS (
    SELECT "SeriesInstanceUID",
           COUNT(DISTINCT "ImageOrientationPatient") AS orientation_cnt
    FROM inst
    GROUP BY "SeriesInstanceUID"
),
pix_cnt AS (
    SELECT "SeriesInstanceUID",
           COUNT(DISTINCT pix_space) AS pixspace_cnt,
           COUNT(DISTINCT "Rows")    AS rows_cnt,
           COUNT(DISTINCT "Columns") AS cols_cnt
    FROM inst
    GROUP BY "SeriesInstanceUID"
),
/* inter-slice spacing uniqueness */
z_spacing AS (
    SELECT
        "SeriesInstanceUID",
        ROUND(ABS(z_position -
              LAG(z_position) OVER (PARTITION BY "SeriesInstanceUID"
                                    ORDER BY z_position)),5) AS spacing
    FROM (SELECT DISTINCT "SeriesInstanceUID", z_position FROM inst)
),
z_spacing_cnt AS (
    SELECT "SeriesInstanceUID",
           COUNT(DISTINCT spacing) AS spacing_cnt
    FROM   z_spacing
    WHERE  spacing IS NOT NULL
    GROUP  BY "SeriesInstanceUID"
),
/* main per-series aggregation */
series_agg AS (
    SELECT
        "SeriesInstanceUID",
        MAX("SeriesNumber")  AS series_number,
        MAX("PatientID")     AS patient_id,
        SUM("instance_size") AS size_bytes,
        COUNT(*)             AS image_cnt,
        COUNT(DISTINCT z_position) AS z_cnt
    FROM inst
    GROUP BY "SeriesInstanceUID"
),
/* combine and apply all filters */
series_filtered AS (
    SELECT
        a."SeriesInstanceUID",
        a.series_number,
        a.patient_id,
        a.size_bytes,
        oc.orientation_cnt,
        pc.pixspace_cnt,
        pc.rows_cnt,
        pc.cols_cnt,
        zs.spacing_cnt,
        a.image_cnt,
        a.z_cnt,
        ABS(o.rx*o.cy - o.ry*o.cx) AS cross_z
    FROM series_agg      a
    JOIN orientation     o  ON a."SeriesInstanceUID" = o."SeriesInstanceUID"
    JOIN orientation_cnt oc ON a."SeriesInstanceUID" = oc."SeriesInstanceUID"
    JOIN pix_cnt         pc ON a."SeriesInstanceUID" = pc."SeriesInstanceUID"
    JOIN z_spacing_cnt   zs ON a."SeriesInstanceUID" = zs."SeriesInstanceUID"
)
SELECT
    "SeriesInstanceUID",
    series_number,
    patient_id,
    ROUND(size_bytes/1048576.0,2) AS series_size_mib
FROM   series_filtered
WHERE  orientation_cnt = 1          /* single ImageOrientationPatient */
  AND  pixspace_cnt    = 1          /* uniform PixelSpacing */
  AND  rows_cnt        = 1          /* uniform Rows */
  AND  cols_cnt        = 1          /* uniform Columns */
  AND  spacing_cnt     = 1          /* single slice interval */
  AND  image_cnt       = z_cnt      /* no duplicate slices */
  AND  cross_z BETWEEN 0.99 AND 1.01
ORDER BY series_size_mib DESC NULLS LAST
LIMIT 5;