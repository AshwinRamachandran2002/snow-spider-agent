WITH base_data AS (
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "StudyInstanceUID",
        "PatientID",
        "SOPInstanceUID",
        "instance_size",
        "ImageOrientationPatient",
        "ImagePositionPatient",
        "SliceThickness",
        CAST("Exposure" AS FLOAT) AS "Exposure",
        "Rows",
        "Columns",
        "PixelSpacing"
    FROM
        "IDC"."IDC_V17"."DICOM_ALL"
    WHERE
        "Modality" = 'CT'
        AND "collection_id" != 'NLST'
        AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70', '1.2.840.10008.1.2.4.51')
        AND NOT ("ImageType" ILIKE '%LOCALIZER%')
),
series_filtered AS (
    SELECT
        "SeriesInstanceUID",
        MAX("SeriesNumber") AS "SeriesNumber",
        MAX("StudyInstanceUID") AS "StudyInstanceUID",
        MAX("PatientID") AS "PatientID",
        COUNT(DISTINCT "SOPInstanceUID") AS "NumInstances",
        COUNT(DISTINCT "SliceThickness") AS "NumDistinctSliceThickness",
        COUNT(DISTINCT "Exposure") AS "NumDistinctExposureValues",
        MAX("Exposure") AS "MaxExposureValue",
        MIN("Exposure") AS "MinExposureValue",
        MAX("Exposure") - MIN("Exposure") AS "ExposureRange",
        SUM("instance_size") / (1024 * 1024) AS "SeriesSizeMB",
        MAX("ImageOrientationPatient") AS "ImageOrientationPatient",
        MAX("PixelSpacing") AS "PixelSpacing",
        MAX("Rows") AS "Rows",
        MAX("Columns") AS "Columns"
    FROM
        base_data
    GROUP BY
        "SeriesInstanceUID"
    HAVING
        COUNT(DISTINCT "ImageOrientationPatient") = 1
        AND COUNT(DISTINCT "PixelSpacing") = 1
        AND COUNT(DISTINCT "Rows") = 1
        AND COUNT(DISTINCT "Columns") = 1
        AND COUNT(DISTINCT "SOPInstanceUID") = COUNT(DISTINCT "ImagePositionPatient")
),
slice_diffs AS (
    SELECT
        bd."SeriesInstanceUID",
        bd."SOPInstanceUID",
        bd."ImagePositionPatient"[2]::FLOAT AS "Zposition",
        ROW_NUMBER() OVER (PARTITION BY bd."SeriesInstanceUID" ORDER BY bd."ImagePositionPatient"[2]::FLOAT) AS row_num
    FROM
        base_data bd
    INNER JOIN
        series_filtered sf ON bd."SeriesInstanceUID" = sf."SeriesInstanceUID"
),
slice_intervals AS (
    SELECT
        sd."SeriesInstanceUID",
        sd."Zposition",
        sd_next."Zposition" AS "NextZposition",
        ABS(sd_next."Zposition" - sd."Zposition") AS "SliceInterval"
    FROM
        slice_diffs sd
    INNER JOIN
        slice_diffs sd_next ON
            sd."SeriesInstanceUID" = sd_next."SeriesInstanceUID"
            AND sd.row_num + 1 = sd_next.row_num
),
slice_interval_stats AS (
    SELECT
        "SeriesInstanceUID",
        MAX("SliceInterval") AS "MaxSliceIntervalDiff",
        MIN("SliceInterval") AS "MinSliceIntervalDiff",
        MAX("SliceInterval") - MIN("SliceInterval") AS "ToleranceSliceIntervalDiff"
    FROM
        slice_intervals
    GROUP BY
        "SeriesInstanceUID"
),
dot_product AS (
    SELECT
        sf."SeriesInstanceUID",
        ABS(
            (sf."ImageOrientationPatient"[0]::FLOAT * sf."ImageOrientationPatient"[4]::FLOAT)
            - (sf."ImageOrientationPatient"[1]::FLOAT * sf."ImageOrientationPatient"[3]::FLOAT)
        ) AS "MaxDotProduct"
    FROM
        series_filtered sf
)
SELECT
    sf."SeriesInstanceUID",
    sf."SeriesNumber",
    sf."StudyInstanceUID",
    sf."PatientID",
    ROUND(dp."MaxDotProduct", 4) AS "MaxDotProduct",
    sf."NumInstances",
    sf."NumDistinctSliceThickness",
    ROUND(sis."MaxSliceIntervalDiff", 4) AS "MaxSliceIntervalDiff",
    ROUND(sis."MinSliceIntervalDiff", 4) AS "MinSliceIntervalDiff",
    ROUND(sis."ToleranceSliceIntervalDiff", 4) AS "ToleranceSliceIntervalDiff",
    sf."NumDistinctExposureValues",
    ROUND(sf."MaxExposureValue", 4) AS "MaxExposureValue",
    ROUND(sf."MinExposureValue", 4) AS "MinExposureValue",
    ROUND(sf."ExposureRange", 4) AS "ExposureRange",
    ROUND(sf."SeriesSizeMB", 4) AS "SeriesSizeMB"
FROM
    series_filtered sf
JOIN
    dot_product dp ON sf."SeriesInstanceUID" = dp."SeriesInstanceUID"
JOIN
    slice_interval_stats sis ON sf."SeriesInstanceUID" = sis."SeriesInstanceUID"
WHERE
    ABS(dp."MaxDotProduct" - 1.0) <= 0.01
ORDER BY
    sis."ToleranceSliceIntervalDiff" DESC NULLS LAST,
    sf."ExposureRange" DESC NULLS LAST,
    sf."SeriesInstanceUID" DESC NULLS LAST;