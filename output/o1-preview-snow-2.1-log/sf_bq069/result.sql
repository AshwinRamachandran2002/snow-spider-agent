WITH
qc_pass AS (
    SELECT DISTINCT "SeriesInstanceUID"
    FROM (
        SELECT
            s.*,
            ABS(s."ImagePositionPatient"[2]::FLOAT - LAG(s."ImagePositionPatient"[2]::FLOAT) OVER (
                PARTITION BY s."SeriesInstanceUID" 
                ORDER BY s."ImagePositionPatient"[2]::FLOAT
            )) AS "SliceIntervalDifference"
        FROM (
            SELECT *
            FROM IDC.IDC_V17.DICOM_ALL
            WHERE
                "Modality" = 'CT'
                AND "collection_id" != 'NLST'
                AND "TransferSyntaxUID" NOT IN (
                    '1.2.840.10008.1.2.4.70', 
                    '1.2.840.10008.1.2.4.51'
                )
                AND "SeriesInstanceUID" NOT IN (
                    SELECT DISTINCT t."SeriesInstanceUID"
                    FROM IDC.IDC_V17.DICOM_ALL t, LATERAL FLATTEN(input => t."ImageType") f
                    WHERE f.value::STRING ILIKE '%LOCALIZER%'
                )
        ) s
        QUALIFY
            COUNT(DISTINCT s."ImageOrientationPatient") OVER (PARTITION BY s."SeriesInstanceUID") = 1
            AND COUNT(DISTINCT TO_VARCHAR(s."PixelSpacing")) OVER (PARTITION BY s."SeriesInstanceUID") = 1
            AND COUNT(*) OVER (PARTITION BY s."SeriesInstanceUID") = COUNT(DISTINCT TO_VARCHAR(s."ImagePositionPatient")) OVER (PARTITION BY s."SeriesInstanceUID")
            AND COUNT(DISTINCT LEFT(
                TO_VARCHAR(s."ImagePositionPatient"), 
                CHARINDEX(',', TO_VARCHAR(s."ImagePositionPatient"), CHARINDEX(',', TO_VARCHAR(s."ImagePositionPatient")) + 1) - 1
            )) OVER (PARTITION BY s."SeriesInstanceUID") = 1
            AND COUNT(DISTINCT s."Rows") OVER (PARTITION BY s."SeriesInstanceUID") = 1
            AND COUNT(DISTINCT s."Columns") OVER (PARTITION BY s."SeriesInstanceUID") = 1
    )
),
orientation AS (
    SELECT
        "SeriesInstanceUID",
        "ImageOrientationPatient"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" IN (SELECT "SeriesInstanceUID" FROM qc_pass)
    GROUP BY "SeriesInstanceUID", "ImageOrientationPatient"
),
dot_products AS (
    SELECT
        "SeriesInstanceUID",
        ("u2" * "v3" - "u3" * "v2") * 0 +
        ("u3" * "v1" - "u1" * "v3") * 0 +
        ("u1" * "v2" - "u2" * "v1") * 1 AS "dot_product"
    FROM (
        SELECT
            "SeriesInstanceUID",
            "ImageOrientationPatient"[0]::FLOAT AS "u1",
            "ImageOrientationPatient"[1]::FLOAT AS "u2",
            "ImageOrientationPatient"[2]::FLOAT AS "u3",
            "ImageOrientationPatient"[3]::FLOAT AS "v1",
            "ImageOrientationPatient"[4]::FLOAT AS "v2",
            "ImageOrientationPatient"[5]::FLOAT AS "v3"
        FROM orientation
    )
),
filtered_series AS (
    SELECT
        sub."SeriesInstanceUID",
        MAX(sub."SeriesNumber") AS "SeriesNumber",
        MAX(sub."StudyInstanceUID") AS "StudyInstanceUID",
        MAX(sub."PatientID") AS "PatientID",
        COUNT(*) AS "TotalSOPInstances",
        COUNT(DISTINCT sub."SliceThickness") AS "NumberOfDistinctSliceThicknessValues",
        ROUND(MAX(sub."SliceIntervalDifference"), 4) AS "MaxSliceIntervalDifference",
        ROUND(MIN(sub."SliceIntervalDifference"), 4) AS "MinSliceIntervalDifference",
        ROUND(MAX(sub."SliceIntervalDifference") - MIN(sub."SliceIntervalDifference"), 4) AS "SliceIntervalDifferenceTolerance",
        COUNT(DISTINCT sub."Exposure") AS "NumberOfDistinctExposureValues",
        MAX(sub."Exposure") AS "MaxExposureValue",
        MIN(sub."Exposure") AS "MinExposureValue",
        MAX(sub."Exposure") - MIN(sub."Exposure") AS "ExposureValueRange",
        ROUND(SUM(sub."instance_size") / 1048576, 4) AS "TotalSeriesSizeMiB"
    FROM (
        SELECT
            s.*,
            ABS(s."ImagePositionPatient"[2]::FLOAT - LAG(s."ImagePositionPatient"[2]::FLOAT) OVER (
                PARTITION BY s."SeriesInstanceUID" 
                ORDER BY s."ImagePositionPatient"[2]::FLOAT
            )) AS "SliceIntervalDifference"
        FROM IDC.IDC_V17.DICOM_ALL s
        WHERE s."SeriesInstanceUID" IN (SELECT "SeriesInstanceUID" FROM qc_pass)
    ) sub
    GROUP BY sub."SeriesInstanceUID"
)
SELECT
    f."SeriesInstanceUID",
    f."SeriesNumber",
    f."StudyInstanceUID",
    f."PatientID",
    ROUND(ABS(d."dot_product"), 4) AS "MaxDotProductValue",
    f."TotalSOPInstances",
    f."NumberOfDistinctSliceThicknessValues",
    f."MaxSliceIntervalDifference",
    f."MinSliceIntervalDifference",
    f."SliceIntervalDifferenceTolerance",
    f."NumberOfDistinctExposureValues",
    f."MaxExposureValue",
    f."MinExposureValue",
    f."ExposureValueRange",
    f."TotalSeriesSizeMiB"
FROM filtered_series f
JOIN dot_products d ON f."SeriesInstanceUID" = d."SeriesInstanceUID"
WHERE ROUND(ABS(d."dot_product"), 4) BETWEEN 0.9900 AND 1.0100
ORDER BY
    f."SliceIntervalDifferenceTolerance" DESC NULLS LAST,
    f."ExposureValueRange" DESC NULLS LAST,
    f."SeriesInstanceUID" DESC NULLS LAST