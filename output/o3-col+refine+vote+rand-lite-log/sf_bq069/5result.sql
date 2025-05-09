/*  Quality-controlled CT series report  (Snowflake dialect)
    --------------------------------------------------------
    – drop NLST, JPEG-compressed and localizer series
    – geometry consistency checks
    – slice-spacing, exposure and size statistics
*/
WITH base AS (   -- preliminary CT rows
    SELECT *
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND "collection_name" <> 'NLST'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',  -- JPEG-LS lossless
                                      '1.2.840.10008.1.2.4.51')  -- JPEG baseline
      AND CAST("ImageType" AS STRING) NOT ILIKE '%LOCALIZER%'
),
geo_ok AS (      -- geometry constraints per series
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "StudyInstanceUID",
        "PatientID",
        COUNT(*)                                     AS num_sop,
        COUNT(DISTINCT TO_VARIANT("ImageOrientationPatient")) = 1  AS ok_orient,
        COUNT(DISTINCT TO_VARIANT("PixelSpacing"))   = 1            AS ok_pixsp,
        COUNT(DISTINCT TO_VARIANT("ImagePositionPatient"))          AS pos_cnt,
        COUNT(DISTINCT CONCAT(
               "ImagePositionPatient"[0]::STRING, ',',
               "ImagePositionPatient"[1]::STRING))  = 1             AS ok_xy,
        COUNT(DISTINCT "Rows")    = 1               AS ok_rows,
        COUNT(DISTINCT "Columns") = 1               AS ok_cols
    FROM base
    GROUP BY 1,2,3,4
    HAVING ok_orient AND ok_pixsp AND ok_xy AND ok_rows AND ok_cols
           AND pos_cnt = num_sop
),
orient AS (      -- pick one orientation row per series
    SELECT
        g.*,
        b."ImageOrientationPatient"[0]::FLOAT AS o0,
        b."ImageOrientationPatient"[1]::FLOAT AS o1,
        b."ImageOrientationPatient"[2]::FLOAT AS o2,
        b."ImageOrientationPatient"[3]::FLOAT AS o3,
        b."ImageOrientationPatient"[4]::FLOAT AS o4,
        b."ImageOrientationPatient"[5]::FLOAT AS o5,
        ROW_NUMBER() OVER (PARTITION BY g."SeriesInstanceUID"
                           ORDER BY b."SOPInstanceUID") AS rn
    FROM geo_ok g
    JOIN base b
      ON g."SeriesInstanceUID" = b."SeriesInstanceUID"
),
orient_ok AS (   -- keep series whose slice normal ≈ [0,0,±1]
    SELECT *
    FROM orient
    WHERE rn = 1
      AND ABS(ABS((o0*o4) - (o1*o3)) - 1) <= 0.01
),
z_vals AS (      -- z-coordinate list
    SELECT
        b."SeriesInstanceUID",
        b."ImagePositionPatient"[2]::FLOAT AS z,
        ROW_NUMBER() OVER (PARTITION BY b."SeriesInstanceUID"
                           ORDER BY b."ImagePositionPatient"[2]::FLOAT) AS rn
    FROM base b
    JOIN orient_ok o ON b."SeriesInstanceUID" = o."SeriesInstanceUID"
),
z_diff AS (
    SELECT
        "SeriesInstanceUID",
        ABS(z - LAG(z) OVER (PARTITION BY "SeriesInstanceUID" ORDER BY rn)) AS dz
    FROM z_vals
),
z_aggr AS (
    SELECT
        "SeriesInstanceUID",
        MAX(dz) AS max_dz,
        MIN(dz) AS min_dz,
        MAX(dz) - MIN(dz) AS tol_dz
    FROM z_diff
    GROUP BY "SeriesInstanceUID"
),
exp_aggr AS (    -- exposure statistics
    SELECT
        b."SeriesInstanceUID",
        COUNT(DISTINCT b."Exposure")                               AS distinct_exp,
        MAX(TRY_TO_NUMBER(NULLIF(b."Exposure", '')))               AS exp_max,
        MIN(TRY_TO_NUMBER(NULLIF(b."Exposure", '')))               AS exp_min,
        MAX(TRY_TO_NUMBER(NULLIF(b."Exposure", '')))
          - MIN(TRY_TO_NUMBER(NULLIF(b."Exposure", '')))           AS exp_range
    FROM base b
    JOIN orient_ok o ON b."SeriesInstanceUID" = o."SeriesInstanceUID"
    GROUP BY b."SeriesInstanceUID"
),
size_aggr AS (   -- total size in MiB
    SELECT
        "SeriesInstanceUID",
        SUM("instance_size") / (1024.0*1024.0) AS series_mib
    FROM base
    GROUP BY "SeriesInstanceUID"
)
SELECT
    o."SeriesInstanceUID"                     AS "series_uid",
    o."SeriesNumber"                          AS "series_no",
    o."StudyInstanceUID"                      AS "study_uid",
    o."PatientID"                             AS "patient_id",
    ABS((o.o0*o.o4) - (o.o1*o.o3))            AS "max_dot_prod",
    o.num_sop                                 AS "num_sop",
    COUNT(DISTINCT b."SliceThickness")        AS "distinct_thk",
    z.max_dz                                  AS "max_dz",
    z.min_dz                                  AS "min_dz",
    z.tol_dz                                  AS "tol_dz",
    e.distinct_exp                            AS "distinct_exp",
    e.exp_max                                 AS "exp_max",
    e.exp_min                                 AS "exp_min",
    e.exp_range                               AS "exp_range",
    s.series_mib                              AS "series_mib"
FROM orient_ok o
JOIN base      b ON o."SeriesInstanceUID" = b."SeriesInstanceUID"
JOIN z_aggr    z ON o."SeriesInstanceUID" = z."SeriesInstanceUID"
JOIN exp_aggr  e ON o."SeriesInstanceUID" = e."SeriesInstanceUID"
JOIN size_aggr s ON o."SeriesInstanceUID" = s."SeriesInstanceUID"
GROUP BY
    o."SeriesInstanceUID", o."SeriesNumber", o."StudyInstanceUID",
    o."PatientID", o.o0, o.o1, o.o3, o.o4, o.num_sop,
    z.max_dz, z.min_dz, z.tol_dz,
    e.distinct_exp, e.exp_max, e.exp_min, e.exp_range,
    s.series_mib
ORDER BY
    z.tol_dz    DESC NULLS LAST,
    e.exp_range DESC NULLS LAST,
    o."SeriesInstanceUID" DESC;