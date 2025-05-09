WITH series_stats AS (
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID",
        SUM("instance_size") / (1024 * 1024) AS "SeriesSize_MiB",
        COUNT(DISTINCT "SliceThickness") AS "SliceThickness_variations",
        COUNT(DISTINCT "ImageOrientationPatient") AS "ImageOrientationPatient_variations",
        COUNT(DISTINCT "PixelSpacing") AS "PixelSpacing_variations",
        COUNT(DISTINCT "Rows") AS "Rows_variations",
        COUNT(DISTINCT "Columns") AS "Columns_variations",
        MAX(TRY_TO_DOUBLE("ImageOrientationPatient"[0]::STRING)) AS r1,
        MAX(TRY_TO_DOUBLE("ImageOrientationPatient"[1]::STRING)) AS r2,
        MAX(TRY_TO_DOUBLE("ImageOrientationPatient"[2]::STRING)) AS r3,
        MAX(TRY_TO_DOUBLE("ImageOrientationPatient"[3]::STRING)) AS c1,
        MAX(TRY_TO_DOUBLE("ImageOrientationPatient"[4]::STRING)) AS c2,
        MAX(TRY_TO_DOUBLE("ImageOrientationPatient"[5]::STRING)) AS c3
    FROM "IDC"."IDC_V17"."DICOM_ALL"
    WHERE
        "Modality" = 'CT'
        AND "ImageType" NOT ILIKE '%LOCALIZER%'
        AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70', '1.2.840.10008.1.2.4.51')
    GROUP BY
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID"
    HAVING
        COUNT(DISTINCT "SliceThickness") = 1
        AND COUNT(DISTINCT "ImageOrientationPatient") = 1
        AND COUNT(DISTINCT "PixelSpacing") = 1
        AND COUNT(DISTINCT "Rows") = 1
        AND COUNT(DISTINCT "Columns") = 1
        AND r1 IS NOT NULL
        AND r2 IS NOT NULL
        AND r3 IS NOT NULL
        AND c1 IS NOT NULL
        AND c2 IS NOT NULL
        AND c3 IS NOT NULL
)
SELECT
    "SeriesInstanceUID",
    "SeriesNumber",
    "PatientID",
    ROUND("SeriesSize_MiB", 4) AS "SeriesSize_MiB"
FROM (
    SELECT
        *,
        (r2 * c3 - r3 * c2) AS n1,
        (r3 * c1 - r1 * c3) AS n2,
        (r1 * c2 - r2 * c1) AS n3,
        SQRT(
            POWER((r2 * c3 - r3 * c2), 2) + POWER((r3 * c1 - r1 * c3), 2) + POWER((r1 * c2 - r2 * c1), 2)
        ) AS N_mag,
        ((r1 * c2 - r2 * c1) / NULLIF(SQRT(
            POWER((r2 * c3 - r3 * c2), 2) + POWER((r3 * c1 - r1 * c3), 2) + POWER((r1 * c2 - r2 * c1), 2)
        ), 0)) AS n3_normalized
    FROM series_stats
) AS t
WHERE
    n3_normalized IS NOT NULL
    AND ABS(n3_normalized) BETWEEN 0.99 AND 1.01
ORDER BY
    "SeriesSize_MiB" DESC NULLS LAST
LIMIT 5;