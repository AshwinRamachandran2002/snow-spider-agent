WITH localizer_series AS (
    SELECT DISTINCT "SeriesInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL, LATERAL FLATTEN(input => "ImageType") AS f
    WHERE "Modality" = 'CT' AND f.value::STRING = 'LOCALIZER'
),
filtered_series AS (
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID",
        "instance_size",
        "SliceThickness",
        "KVP",
        "ImageOrientationPatient",
        "PixelSpacing",
        "ImagePositionPatient",
        "Rows",
        "Columns"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE
        "Modality" = 'CT'
        AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70', '1.2.840.10008.1.2.4.51')
        AND "SeriesInstanceUID" NOT IN (SELECT "SeriesInstanceUID" FROM localizer_series)
),
series_consistency AS (
    SELECT
        "SeriesInstanceUID",
        COUNT(DISTINCT "SliceThickness") AS num_SliceThickness,
        COUNT(DISTINCT "KVP") AS num_KVP,
        COUNT(DISTINCT "ImageOrientationPatient") AS num_ImageOrientationPatient,
        COUNT(DISTINCT "PixelSpacing") AS num_PixelSpacing,
        COUNT(DISTINCT "ImagePositionPatient") AS num_ImagePositionPatient,
        COUNT(DISTINCT "Rows") AS num_Rows,
        COUNT(DISTINCT "Columns") AS num_Columns
    FROM filtered_series
    GROUP BY "SeriesInstanceUID"
),
consistent_series AS (
    SELECT s."SeriesInstanceUID",
        MAX(s."SeriesNumber") AS "SeriesNumber",
        MAX(s."PatientID") AS "PatientID",
        ROUND(SUM(s."instance_size")/(1024*1024), 4) AS "SeriesSize_MiB",
        MAX(s."ImageOrientationPatient") AS "ImageOrientationPatient"
    FROM filtered_series s
    INNER JOIN series_consistency c ON s."SeriesInstanceUID" = c."SeriesInstanceUID"
    WHERE c.num_SliceThickness = 1
      AND c.num_KVP = 1
      AND c.num_ImageOrientationPatient = 1
      AND c.num_PixelSpacing = 1
      AND c.num_ImagePositionPatient = 1
      AND c.num_Rows = 1
      AND c.num_Columns = 1
    GROUP BY s."SeriesInstanceUID"
),
series_with_orientation AS (
    SELECT
        cs."SeriesInstanceUID",
        cs."SeriesNumber",
        cs."PatientID",
        cs."SeriesSize_MiB",
        TO_DOUBLE(cs."ImageOrientationPatient"[0]) AS IOP_R1,
        TO_DOUBLE(cs."ImageOrientationPatient"[1]) AS IOP_R2,
        TO_DOUBLE(cs."ImageOrientationPatient"[2]) AS IOP_R3,
        TO_DOUBLE(cs."ImageOrientationPatient"[3]) AS IOP_C1,
        TO_DOUBLE(cs."ImageOrientationPatient"[4]) AS IOP_C2,
        TO_DOUBLE(cs."ImageOrientationPatient"[5]) AS IOP_C3
    FROM consistent_series cs
),
series_with_z_alignment AS (
    SELECT *,
        ABS(IOP_R1 * IOP_C2 - IOP_R2 * IOP_C1) AS N3
    FROM series_with_orientation
    WHERE IOP_R1 IS NOT NULL AND IOP_R2 IS NOT NULL AND IOP_R3 IS NOT NULL AND IOP_C1 IS NOT NULL AND IOP_C2 IS NOT NULL AND IOP_C3 IS NOT NULL
),
final_series AS (
    SELECT "SeriesInstanceUID", "SeriesNumber", "PatientID", "SeriesSize_MiB"
    FROM series_with_z_alignment
    WHERE N3 BETWEEN 0.99 AND 1.01
)
SELECT "SeriesInstanceUID", "SeriesNumber", "PatientID", "SeriesSize_MiB"
FROM final_series
ORDER BY "SeriesSize_MiB" DESC NULLS LAST
LIMIT 5;