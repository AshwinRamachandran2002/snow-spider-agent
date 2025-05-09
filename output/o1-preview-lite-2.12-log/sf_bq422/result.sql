WITH
-- Filter CT images from the 'nlst' collection in DICOM_PIVOT table
CT_PIVOT AS (
    SELECT *
    FROM "IDC"."IDC_V17"."DICOM_PIVOT"
    WHERE "Modality" = 'CT' AND "collection_id" = 'nlst'
),
-- Compute slice thickness difference per patient
SliceThicknessDiff AS (
    SELECT "PatientID",
           MAX(TRY_CAST("SliceThickness" AS FLOAT)) - MIN(TRY_CAST("SliceThickness" AS FLOAT)) AS "SliceThicknessDifference"
    FROM CT_PIVOT
    WHERE "SliceThickness" IS NOT NULL AND TRY_CAST("SliceThickness" AS FLOAT) IS NOT NULL
    GROUP BY "PatientID"
),
-- Get top 3 patients with highest slice thickness difference
Top3SlicePatients AS (
    SELECT "PatientID"
    FROM SliceThicknessDiff
    ORDER BY "SliceThicknessDifference" DESC NULLS LAST
    LIMIT 3
),
-- Filter CT images from the 'nlst' collection in DICOM_ALL table for Exposure
CT_ALL AS (
    SELECT *
    FROM "IDC"."IDC_V17"."DICOM_ALL"
    WHERE "Modality" = 'CT' AND "collection_id" = 'nlst'
),
-- Compute exposure difference per patient
ExposureDiff AS (
    SELECT "PatientID",
           MAX(TRY_CAST("Exposure" AS FLOAT)) - MIN(TRY_CAST("Exposure" AS FLOAT)) AS "ExposureDifference"
    FROM CT_ALL
    WHERE "Exposure" IS NOT NULL AND TRY_CAST("Exposure" AS FLOAT) IS NOT NULL
    GROUP BY "PatientID"
),
-- Get top 3 patients with highest exposure difference
Top3ExposurePatients AS (
    SELECT "PatientID"
    FROM ExposureDiff
    ORDER BY "ExposureDifference" DESC NULLS LAST
    LIMIT 3
),
-- Combine top patients
TopPatients AS (
    SELECT "PatientID", 'SliceThicknessDifference' AS "Category" FROM Top3SlicePatients
    UNION ALL
    SELECT "PatientID", 'ExposureDifference' AS "Category" FROM Top3ExposurePatients
),
-- Compute series sizes
SeriesSizes AS (
    SELECT "PatientID", "SeriesInstanceUID", SUM("instance_size") / (1024 * 1024) AS "SeriesSizeMiB"
    FROM CT_PIVOT
    WHERE "PatientID" IN (SELECT "PatientID" FROM TopPatients)
    GROUP BY "PatientID", "SeriesInstanceUID"
),
-- Compute average series size per patient
AverageSeriesSize AS (
    SELECT "PatientID", ROUND(AVG("SeriesSizeMiB"), 4) AS "Average_Series_Size_MiB"
    FROM SeriesSizes
    GROUP BY "PatientID"
)
-- Final output with categories
SELECT tp."Category", ass."PatientID", ass."Average_Series_Size_MiB"
FROM TopPatients tp
JOIN AverageSeriesSize ass ON tp."PatientID" = ass."PatientID"
ORDER BY tp."Category", ass."Average_Series_Size_MiB" DESC;