WITH base AS (          /* 1. CT images (non‑NLST) and non‑JPEG transfer syntaxes            */
    SELECT *
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND "collection_id" <> 'nlst'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                      '1.2.840.10008.1.2.4.51')
      AND "ImageOrientationPatient" IS NOT NULL
      AND "ImagePositionPatient"   IS NOT NULL
      AND "PixelSpacing"           IS NOT NULL
      AND "Rows"                   IS NOT NULL
      AND "Columns"                IS NOT NULL
),
non_localizer AS (      /* 2. exclude LOCALIZER images                                        */
    SELECT *
    FROM base
    WHERE "ImageType" IS NULL
          OR "ImageType"::STRING NOT ILIKE '%LOCALIZER%'
),
series_param_ok AS (    /* 3. series with constant geometry & in‑plane position               */
    SELECT "SeriesInstanceUID"
    FROM non_localizer
    GROUP BY "SeriesInstanceUID"
    HAVING COUNT(DISTINCT "PixelSpacing")             = 1
       AND COUNT(DISTINCT "Rows")                     = 1
       AND COUNT(DISTINCT "Columns")                  = 1
       AND COUNT(DISTINCT "ImageOrientationPatient")  = 1
       AND COUNT(DISTINCT ("ImagePositionPatient"[0])) = 1
       AND COUNT(DISTINCT ("ImagePositionPatient"[1])) = 1
),
orientation_ok AS (     /* 4. ensure |cz| ≈ 1                                                 */
    SELECT n."SeriesInstanceUID",
           ABS( (MAX((n."ImageOrientationPatient"[0])::FLOAT) *
                 MAX((n."ImageOrientationPatient"[4])::FLOAT))
               - (MAX((n."ImageOrientationPatient"[1])::FLOAT) *
                 MAX((n."ImageOrientationPatient"[3])::FLOAT)) ) AS abs_cz
    FROM non_localizer n
    JOIN series_param_ok sp
      ON n."SeriesInstanceUID" = sp."SeriesInstanceUID"
    GROUP BY n."SeriesInstanceUID"
    HAVING abs_cz BETWEEN 0.99 AND 1.01
),
z_ok AS (               /* 5. #images equals #unique z‑positions (no duplicate slices)        */
    SELECT "SeriesInstanceUID"
    FROM non_localizer
    WHERE "SeriesInstanceUID" IN (SELECT "SeriesInstanceUID" FROM orientation_ok)
    GROUP BY "SeriesInstanceUID"
    HAVING COUNT(*) = COUNT(DISTINCT ("ImagePositionPatient"[2]))
),
size_tab AS (           /* 6. compute total series size (MiB)                                 */
    SELECT "SeriesInstanceUID",
           MAX("SeriesNumber")  AS "SeriesNumber",
           MAX("PatientID")     AS "PatientID",
           SUM("instance_size")/1048576.0 AS "series_size_MiB"
    FROM non_localizer
    WHERE "SeriesInstanceUID" IN (SELECT "SeriesInstanceUID" FROM z_ok)
    GROUP BY "SeriesInstanceUID"
)
SELECT "SeriesInstanceUID",
       "SeriesNumber",
       "PatientID",
       ROUND("series_size_MiB", 4) AS "series_size_MiB"
FROM size_tab
ORDER BY "series_size_MiB" DESC NULLS LAST,
         "SeriesInstanceUID"
LIMIT 5;