WITH SeriesCT AS (
    SELECT 
        d."SeriesInstanceUID",
        MAX(d."SeriesNumber") AS "SeriesNumber",
        MAX(d."PatientID") AS "PatientID",
        SUM(d."instance_size") / (1024 * 1024) AS "SeriesSize_MiB",
        COUNT(DISTINCT d."SliceThickness") AS "SliceThicknessCount",
        COUNT(DISTINCT d."Exposure") AS "ExposureCount",
        COUNT(DISTINCT d."ImageOrientationPatient") AS "ImageOrientationPatientCount",
        COUNT(DISTINCT d."PixelSpacing") AS "PixelSpacingCount",
        COUNT(DISTINCT d."Rows") AS "RowsCount",
        COUNT(DISTINCT d."Columns") AS "ColumnsCount",
        ANY_VALUE(d."ImageOrientationPatient") AS "ImageOrientationPatient",
        MAX(CASE 
            WHEN REGEXP_LIKE(ARRAY_TO_STRING(d."ImageType", ','), 'LOCALIZER|SCOUT', 'i') THEN 1 
            ELSE 0 
        END) AS HasLocalizer,
        COUNT(*) AS "InstanceCount"
    FROM "IDC"."IDC_V17"."DICOM_ALL" AS d
    WHERE
        d."Modality" = 'CT'
        AND d."TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70', '1.2.840.10008.1.2.4.51')
        AND d."ImageOrientationPatient" IS NOT NULL
    GROUP BY 
        d."SeriesInstanceUID"
    HAVING
        "SliceThicknessCount" = 1
        AND "ExposureCount" = 1
        AND "ImageOrientationPatientCount" = 1
        AND "PixelSpacingCount" = 1
        AND "RowsCount" = 1
        AND "ColumnsCount" = 1
        AND HasLocalizer = 0
        AND "InstanceCount" > 1
),
SeriesWithNormalZ AS (
    SELECT 
        s."SeriesInstanceUID", 
        s."SeriesNumber", 
        s."PatientID", 
        s."SeriesSize_MiB",
        s."ImageOrientationPatient",
        -- Get direction cosines
        s."ImageOrientationPatient"[0]::FLOAT AS r1,
        s."ImageOrientationPatient"[1]::FLOAT AS r2,
        s."ImageOrientationPatient"[2]::FLOAT AS r3,
        s."ImageOrientationPatient"[3]::FLOAT AS c1,
        s."ImageOrientationPatient"[4]::FLOAT AS c2,
        s."ImageOrientationPatient"[5]::FLOAT AS c3,
        -- Compute normal vector z-component
        ABS(
            s."ImageOrientationPatient"[0]::FLOAT * s."ImageOrientationPatient"[4]::FLOAT - s."ImageOrientationPatient"[1]::FLOAT * s."ImageOrientationPatient"[3]::FLOAT
        ) AS abs_nz
    FROM SeriesCT s
)
SELECT 
    "SeriesInstanceUID", "SeriesNumber", "PatientID", ROUND("SeriesSize_MiB", 4) AS "SeriesSize_MiB"
FROM SeriesWithNormalZ
WHERE
    abs_nz BETWEEN 0.99 AND 1.01
ORDER BY "SeriesSize_MiB" DESC NULLS LAST
LIMIT 5;