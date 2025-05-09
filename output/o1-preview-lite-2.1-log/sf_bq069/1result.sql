WITH FilteredInstances AS (
    SELECT
        *,
        TRY_TO_DOUBLE("SliceThickness") AS SliceThicknessDouble,
        TRY_TO_DOUBLE("Exposure") AS ExposureDouble,
        TRY_TO_DOUBLE("ImagePositionPatient"[2]::STRING) AS zPosition,
        TRY_TO_DOUBLE("ImageOrientationPatient"[0]::STRING) AS IOP1,
        TRY_TO_DOUBLE("ImageOrientationPatient"[1]::STRING) AS IOP2,
        TRY_TO_DOUBLE("ImageOrientationPatient"[2]::STRING) AS IOP3,
        TRY_TO_DOUBLE("ImageOrientationPatient"[3]::STRING) AS IOP4,
        TRY_TO_DOUBLE("ImageOrientationPatient"[4]::STRING) AS IOP5,
        TRY_TO_DOUBLE("ImageOrientationPatient"[5]::STRING) AS IOP6,
        TRY_TO_DOUBLE("ImagePositionPatient"[0]::STRING) AS ImagePositionX,
        TRY_TO_DOUBLE("ImagePositionPatient"[1]::STRING) AS ImagePositionY
    FROM
        "IDC"."IDC_V17"."DICOM_ALL"
    WHERE
        "Modality" = 'CT' AND
        "collection_id" != 'NLST' AND
        "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70', '1.2.840.10008.1.2.4.51') AND
        NOT ("ImageType" ILIKE '%LOCALIZER%')
),

SeriesChecks AS (
    SELECT
        "SeriesInstanceUID",
        COUNT(DISTINCT "ImageOrientationPatient") AS DistinctImageOrientationPatientCount,
        COUNT(DISTINCT "PixelSpacing") AS DistinctPixelSpacingCount,
        COUNT(*) AS TotalSOPInstances,
        COUNT(DISTINCT "ImagePositionPatient") AS DistinctImagePositionPatientCount,
        COUNT(DISTINCT CONCAT(
            TO_VARCHAR(TRY_TO_DOUBLE("ImagePositionPatient"[0]::STRING)),
            ',',
            TO_VARCHAR(TRY_TO_DOUBLE("ImagePositionPatient"[1]::STRING))
        )) AS DistinctFirstTwoComponents,
        COUNT(DISTINCT "Rows") AS DistinctRowsCount,
        COUNT(DISTINCT "Columns") AS DistinctColumnsCount
    FROM
        FilteredInstances
    GROUP BY
        "SeriesInstanceUID"
    HAVING
        DistinctImageOrientationPatientCount = 1 AND
        DistinctPixelSpacingCount = 1 AND
        TotalSOPInstances = DistinctImagePositionPatientCount AND
        DistinctFirstTwoComponents = 1 AND
        DistinctRowsCount = 1 AND
        DistinctColumnsCount = 1
),

PerInstanceComputed AS (
    SELECT
        f.*,
        (f.IOP2 * f.IOP6 - f.IOP3 * f.IOP5) AS cp_x,
        (f.IOP3 * f.IOP4 - f.IOP1 * f.IOP6) AS cp_y,
        (f.IOP1 * f.IOP5 - f.IOP2 * f.IOP4) AS cp_z,
        SQRT(
            POWER(f.IOP2 * f.IOP6 - f.IOP3 * f.IOP5, 2) +
            POWER(f.IOP3 * f.IOP4 - f.IOP1 * f.IOP6, 2) +
            POWER(f.IOP1 * f.IOP5 - f.IOP2 * f.IOP4, 2)
        ) AS cp_magnitude,
        ABS(
            (f.IOP1 * f.IOP5 - f.IOP2 * f.IOP4) / 
            NULLIF(
                SQRT(
                    POWER(f.IOP2 * f.IOP6 - f.IOP3 * f.IOP5, 2) +
                    POWER(f.IOP3 * f.IOP4 - f.IOP1 * f.IOP6, 2) +
                    POWER(f.IOP1 * f.IOP5 - f.IOP2 * f.IOP4, 2)
                ), 0)
        ) AS DotProductValue
    FROM
        FilteredInstances f
),

SeriesWithDotProduct AS (
    SELECT
        p."SeriesInstanceUID",
        MAX(p."SeriesNumber") AS "SeriesNumber",
        MAX(p."StudyInstanceUID") AS "StudyInstanceUID",
        MAX(p."PatientID") AS "PatientID",
        MAX(p.DotProductValue) AS MaxDotProductValue
    FROM
        PerInstanceComputed p
    WHERE
        p."SeriesInstanceUID" IN (SELECT "SeriesInstanceUID" FROM SeriesChecks)
    GROUP BY
        p."SeriesInstanceUID"
    HAVING
        MAX(p.DotProductValue) BETWEEN 0.99 AND 1.01
),

SlicePositions AS (
    SELECT DISTINCT
        p."SeriesInstanceUID",
        p.zPosition
    FROM
        PerInstanceComputed p
    WHERE
        p."SeriesInstanceUID" IN (SELECT "SeriesInstanceUID" FROM SeriesWithDotProduct)
),

SliceIntervals AS (
    SELECT
        s."SeriesInstanceUID",
        s.zPosition,
        ROW_NUMBER() OVER (PARTITION BY s."SeriesInstanceUID" ORDER BY s.zPosition) AS rn
    FROM
        SlicePositions s
),

SliceDifferences AS (
    SELECT
        s1."SeriesInstanceUID",
        s1.zPosition,
        s2.zPosition AS NextZPosition,
        ABS(s2.zPosition - s1.zPosition) AS SliceIntervalDifference
    FROM
        SliceIntervals s1
        INNER JOIN SliceIntervals s2
            ON s1."SeriesInstanceUID" = s2."SeriesInstanceUID" AND s1.rn + 1 = s2.rn
),

SeriesSliceIntervals AS (
    SELECT
        s."SeriesInstanceUID",
        MAX(s.SliceIntervalDifference) AS MaxSliceIntervalDifference,
        MIN(s.SliceIntervalDifference) AS MinSliceIntervalDifference
    FROM
        SliceDifferences s
    GROUP BY
        s."SeriesInstanceUID"
)

SELECT
    swd."SeriesInstanceUID",
    swd."SeriesNumber",
    swd."StudyInstanceUID",
    swd."PatientID",
    ROUND(swd.MaxDotProductValue, 4) AS MaxDotProductValue,
    sc.TotalSOPInstances,
    COUNT(DISTINCT pc.SliceThicknessDouble) AS NumberOfDistinctSliceThicknessValues,
    ROUND(ssi.MaxSliceIntervalDifference, 4) AS MaxSliceIntervalDifference,
    ROUND(ssi.MinSliceIntervalDifference, 4) AS MinSliceIntervalDifference,
    ROUND(ssi.MaxSliceIntervalDifference - ssi.MinSliceIntervalDifference, 4) AS SliceIntervalDifferenceTolerance,
    COUNT(DISTINCT pc.ExposureDouble) AS NumberOfDistinctExposureValues,
    MAX(pc.ExposureDouble) AS MaxExposureValue,
    MIN(pc.ExposureDouble) AS MinExposureValue,
    ROUND(MAX(pc.ExposureDouble) - MIN(pc.ExposureDouble), 4) AS ExposureValueRange,
    ROUND(SUM(pc."instance_size") / (1024 * 1024), 4) AS TotalSeriesSizeMiB
FROM
    SeriesWithDotProduct swd
    INNER JOIN SeriesChecks sc
        ON swd."SeriesInstanceUID" = sc."SeriesInstanceUID"
    INNER JOIN PerInstanceComputed pc
        ON swd."SeriesInstanceUID" = pc."SeriesInstanceUID"
    LEFT JOIN SeriesSliceIntervals ssi
        ON swd."SeriesInstanceUID" = ssi."SeriesInstanceUID"
GROUP BY
    swd."SeriesInstanceUID",
    swd."SeriesNumber",
    swd."StudyInstanceUID",
    swd."PatientID",
    swd.MaxDotProductValue,
    sc.TotalSOPInstances,
    ssi.MaxSliceIntervalDifference,
    ssi.MinSliceIntervalDifference
ORDER BY
    SliceIntervalDifferenceTolerance DESC NULLS LAST,
    ExposureValueRange DESC NULLS LAST,
    swd."SeriesInstanceUID" DESC