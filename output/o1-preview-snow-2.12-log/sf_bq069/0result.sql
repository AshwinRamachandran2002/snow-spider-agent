WITH filtered_instances AS (
    SELECT *
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
        AND "collection_id" != 'NLST'
        AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70', '1.2.840.10008.1.2.4.51')
        AND LOWER("ImageType") NOT LIKE '%localizer%'
        AND "ImageOrientationPatient" IS NOT NULL
        AND "PixelSpacing" IS NOT NULL
        AND "ImagePositionPatient" IS NOT NULL
        AND "Rows" IS NOT NULL
        AND "Columns" IS NOT NULL
),
instance_calculations AS (
    SELECT
        *,
        TRY_TO_NUMBER("ImagePositionPatient"[2]::STRING) AS image_position_z,
        TRY_TO_NUMBER("ImagePositionPatient"[0]::STRING) AS image_position_x,
        TRY_TO_NUMBER("ImagePositionPatient"[1]::STRING) AS image_position_y,
        TRY_TO_NUMBER("ImageOrientationPatient"[0]::STRING) AS iop_1,
        TRY_TO_NUMBER("ImageOrientationPatient"[1]::STRING) AS iop_2,
        TRY_TO_NUMBER("ImageOrientationPatient"[2]::STRING) AS iop_3,
        TRY_TO_NUMBER("ImageOrientationPatient"[3]::STRING) AS iop_4,
        TRY_TO_NUMBER("ImageOrientationPatient"[4]::STRING) AS iop_5,
        TRY_TO_NUMBER("ImageOrientationPatient"[5]::STRING) AS iop_6
    FROM filtered_instances
),
instance_dots AS (
    SELECT
        *,
        (iop_2 * iop_6 - iop_3 * iop_5) AS cross_x,
        (iop_3 * iop_4 - iop_1 * iop_6) AS cross_y,
        (iop_1 * iop_5 - iop_2 * iop_4) AS cross_z,
        ABS(iop_1 * iop_5 - iop_2 * iop_4) AS abs_dot_product
    FROM instance_calculations
    WHERE iop_1 IS NOT NULL AND iop_2 IS NOT NULL AND iop_3 IS NOT NULL AND iop_4 IS NOT NULL AND iop_5 IS NOT NULL AND iop_6 IS NOT NULL
),
series_aggregates AS (
    SELECT
        "SeriesInstanceUID",
        MIN("SeriesNumber") AS "SeriesNumber",
        MIN("StudyInstanceUID") AS "StudyInstanceUID",
        MIN("PatientID") AS "PatientID",
        COUNT(DISTINCT "SOPInstanceUID") AS NumInstances,
        COUNT(DISTINCT "ImageOrientationPatient"::STRING) AS num_distinct_image_orientation_patient,
        COUNT(DISTINCT "PixelSpacing"::STRING) AS num_distinct_pixel_spacing,
        COUNT(DISTINCT "Rows") AS num_distinct_rows,
        COUNT(DISTINCT "Columns") AS num_distinct_columns,
        COUNT(DISTINCT "ImagePositionPatient"::STRING) AS num_distinct_image_position_patient,
        COUNT(DISTINCT CONCAT(image_position_x, ',', image_position_y)) AS num_distinct_first_two_components_image_position_patient,
        MAX(abs_dot_product) AS MaxDotProduct,
        ROUND(SUM("instance_size") / (1024 * 1024), 4) AS SeriesSizeMB,
        COUNT(DISTINCT "SliceThickness") AS NumDistinctSliceThickness,
        MIN("Exposure") AS MinExposureValue,
        MAX("Exposure") AS MaxExposureValue,
        COUNT(DISTINCT "Exposure") AS NumDistinctExposureValues
    FROM instance_dots
    GROUP BY "SeriesInstanceUID"
),
slice_intervals AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY "SeriesInstanceUID" ORDER BY image_position_z) AS slice_order
    FROM instance_dots
),
slice_intervals_diff AS (
    SELECT
        s.*,
        LAG(image_position_z) OVER (PARTITION BY "SeriesInstanceUID" ORDER BY slice_order) AS prev_image_position_z,
        ABS(image_position_z - LAG(image_position_z) OVER (PARTITION BY "SeriesInstanceUID" ORDER BY slice_order)) AS slice_interval_diff
    FROM slice_intervals s
),
slice_intervals_stats AS (
    SELECT
        "SeriesInstanceUID",
        MAX(slice_interval_diff) AS MaxSliceIntervalDiff,
        MIN(slice_interval_diff) AS MinSliceIntervalDiff,
        (MAX(slice_interval_diff) - MIN(slice_interval_diff)) AS ToleranceSliceIntervalDiff
    FROM slice_intervals_diff
    WHERE slice_interval_diff IS NOT NULL
    GROUP BY "SeriesInstanceUID"
)
SELECT
    sa."SeriesInstanceUID",
    sa."SeriesNumber",
    sa."StudyInstanceUID",
    sa."PatientID",
    ROUND(sa.MaxDotProduct, 4) AS MaxDotProduct,
    sa.NumInstances,
    sa.NumDistinctSliceThickness,
    ROUND(sis.MaxSliceIntervalDiff, 4) AS MaxSliceIntervalDiff,
    ROUND(sis.MinSliceIntervalDiff, 4) AS MinSliceIntervalDiff,
    ROUND(sis.ToleranceSliceIntervalDiff, 4) AS ToleranceSliceIntervalDiff,
    sa.NumDistinctExposureValues,
    sa.MaxExposureValue,
    sa.MinExposureValue,
    sa.MaxExposureValue - sa.MinExposureValue AS ExposureRange,
    sa.SeriesSizeMB
FROM series_aggregates sa
JOIN slice_intervals_stats sis ON sa."SeriesInstanceUID" = sis."SeriesInstanceUID"
WHERE
    sa.num_distinct_image_orientation_patient = 1
    AND sa.num_distinct_pixel_spacing = 1
    AND sa.num_distinct_rows = 1
    AND sa.num_distinct_columns = 1
    AND sa.NumInstances = sa.num_distinct_image_position_patient
    AND sa.num_distinct_first_two_components_image_position_patient = 1
    AND sa.MaxDotProduct BETWEEN 0.99 AND 1.01
ORDER BY
    sis.ToleranceSliceIntervalDiff DESC NULLS LAST,
    (sa.MaxExposureValue - sa.MinExposureValue) DESC NULLS LAST,
    sa."SeriesInstanceUID" DESC;