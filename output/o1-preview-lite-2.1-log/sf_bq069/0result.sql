WITH filtered_instances AS (
    SELECT
        *,
        ARRAY_TO_STRING("ImageType", ',') AS "ImageType_str",
        ARRAY_TO_STRING("PixelSpacing", ',') AS "PixelSpacing_str",
        ARRAY_TO_STRING("ImageOrientationPatient", ',') AS "ImageOrientationPatient_str",
        ARRAY_TO_STRING("ImagePositionPatient", ',') AS "ImagePositionPatient_str",
        ("ImagePositionPatient"[0])::FLOAT AS "IPP_x",
        ("ImagePositionPatient"[1])::FLOAT AS "IPP_y",
        ("ImagePositionPatient"[2])::FLOAT AS "IPP_z",
        "SliceThickness"::FLOAT AS "SliceThickness_float",
        "Exposure"::FLOAT AS "Exposure_float"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE
        "Modality" = 'CT'
        AND "collection_id" != 'NLST'
        AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70', '1.2.840.10008.1.2.4.51')
        AND ARRAY_TO_STRING("ImageType", ',') NOT LIKE '%LOCALIZER%'
        AND "ImageOrientationPatient" IS NOT NULL
        AND "PixelSpacing" IS NOT NULL
        AND "ImagePositionPatient" IS NOT NULL
        AND "Rows" IS NOT NULL
        AND "Columns" IS NOT NULL
),
valid_series AS (
    SELECT
        "SeriesInstanceUID",
        MIN("SeriesNumber") AS "SeriesNumber",
        MIN("StudyInstanceUID") AS "StudyInstanceUID",
        MIN("PatientID") AS "PatientID",
        COUNT(*) AS "TotalSOPInstances",
        COUNT(DISTINCT "ImageOrientationPatient_str") AS "NumImageOrientationPatient",
        COUNT(DISTINCT "PixelSpacing_str") AS "NumPixelSpacing",
        COUNT(DISTINCT "ImagePositionPatient_str") AS "NumImagePositionPatient",
        COUNT(DISTINCT "SliceThickness_float") AS "NumberOfDistinctSliceThicknessValues",
        MIN("Rows") AS "MinRows",
        MAX("Rows") AS "MaxRows",
        MIN("Columns") AS "MinColumns",
        MAX("Columns") AS "MaxColumns",
        COUNT(DISTINCT CONCAT(TO_VARCHAR("IPP_x"), ',', TO_VARCHAR("IPP_y"))) AS "NumIPP_xy",
        ROUND(SUM("instance_size") / (1024*1024), 4) AS "TotalSeriesSizeMiB",
        MIN("ImageOrientationPatient_str") AS "ImageOrientationPatient_str"
    FROM filtered_instances
    GROUP BY "SeriesInstanceUID"
    HAVING
        COUNT(DISTINCT "ImageOrientationPatient_str") = 1
        AND COUNT(DISTINCT "PixelSpacing_str") = 1
        AND COUNT(DISTINCT "ImagePositionPatient_str") = COUNT(*)
        AND MIN("Rows") = MAX("Rows")
        AND MIN("Columns") = MAX("Columns")
        AND COUNT(DISTINCT CONCAT(TO_VARCHAR("IPP_x"), ',', TO_VARCHAR("IPP_y"))) = 1
),
orientation_computations AS (
    SELECT
        vs.*,
        SPLIT(vs."ImageOrientationPatient_str", ',') AS "IOP_ARRAY_STR"
    FROM valid_series vs
),
series_with_valid_orientation AS (
    SELECT
        oc.*,
        CAST("IOP_ARRAY_STR"[0] AS FLOAT) AS rx,
        CAST("IOP_ARRAY_STR"[1] AS FLOAT) AS ry,
        CAST("IOP_ARRAY_STR"[2] AS FLOAT) AS rz,
        CAST("IOP_ARRAY_STR"[3] AS FLOAT) AS cx,
        CAST("IOP_ARRAY_STR"[4] AS FLOAT) AS cy,
        CAST("IOP_ARRAY_STR"[5] AS FLOAT) AS cz,
        (ry * cz - rz * cy) AS nx,
        (rz * cx - rx * cz) AS ny,
        (rx * cy - ry * cx) AS nz,
        ABS((rx * cy - ry * cx)) AS "MaxDotProductValue"
    FROM orientation_computations oc
    WHERE
        ARRAY_SIZE("IOP_ARRAY_STR") = 6
),
series_with_good_alignment AS (
    SELECT *
    FROM series_with_valid_orientation
    WHERE "MaxDotProductValue" BETWEEN 0.99 AND 1.01
),
slice_differences_with_prev AS (
    SELECT
        si."SeriesInstanceUID",
        si."IPP_z",
        si."SliceThickness_float",
        si."Exposure_float",
        ABS(si."IPP_z" - LAG(si."IPP_z") OVER (PARTITION BY si."SeriesInstanceUID" ORDER BY si."IPP_z")) AS "SliceIntervalDifference"
    FROM filtered_instances si
    WHERE si."SeriesInstanceUID" IN (SELECT "SeriesInstanceUID" FROM series_with_good_alignment)
),
series_slice_stats AS (
    SELECT
        sd."SeriesInstanceUID",
        ROUND(MAX(sd."SliceIntervalDifference"), 4) AS "MaxSliceIntervalDifference",
        ROUND(MIN(sd."SliceIntervalDifference"), 4) AS "MinSliceIntervalDifference",
        ROUND(MAX(sd."SliceIntervalDifference") - MIN(sd."SliceIntervalDifference"), 4) AS "SliceIntervalDifferenceTolerance"
    FROM slice_differences_with_prev sd
    WHERE sd."SliceIntervalDifference" IS NOT NULL
    GROUP BY sd."SeriesInstanceUID"
),
series_exposure_stats AS (
    SELECT
        si."SeriesInstanceUID",
        COUNT(DISTINCT si."Exposure_float") AS "NumberOfDistinctExposureValues",
        ROUND(MAX(si."Exposure_float"), 4) AS "MaxExposureValue",
        ROUND(MIN(si."Exposure_float"), 4) AS "MinExposureValue",
        ROUND(MAX(si."Exposure_float") - MIN(si."Exposure_float"), 4) AS "ExposureValueRange"
    FROM filtered_instances si
    WHERE si."Exposure_float" IS NOT NULL
    AND si."SeriesInstanceUID" IN (SELECT "SeriesInstanceUID" FROM series_with_good_alignment)
    GROUP BY si."SeriesInstanceUID"
),
final_report AS (
    SELECT
        sg."SeriesInstanceUID",
        sg."SeriesNumber",
        sg."StudyInstanceUID",
        sg."PatientID",
        ROUND(sg."MaxDotProductValue", 4) AS "MaxDotProductValue",
        sg."TotalSOPInstances",
        sg."NumberOfDistinctSliceThicknessValues",
        ss."MaxSliceIntervalDifference",
        ss."MinSliceIntervalDifference",
        ss."SliceIntervalDifferenceTolerance",
        es."NumberOfDistinctExposureValues",
        es."MaxExposureValue",
        es."MinExposureValue",
        es."ExposureValueRange",
        sg."TotalSeriesSizeMiB"
    FROM series_with_good_alignment sg
    LEFT JOIN series_slice_stats ss ON sg."SeriesInstanceUID" = ss."SeriesInstanceUID"
    LEFT JOIN series_exposure_stats es ON sg."SeriesInstanceUID" = es."SeriesInstanceUID"
)
SELECT
    *
FROM final_report
ORDER BY
    "SliceIntervalDifferenceTolerance" DESC NULLS LAST,
    "ExposureValueRange" DESC NULLS LAST,
    "SeriesInstanceUID" DESC;