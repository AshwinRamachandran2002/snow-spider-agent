WITH series_data AS (
  SELECT
    "SeriesInstanceUID",
    "SeriesNumber",
    "StudyInstanceUID",
    "PatientID",
    "ImageOrientationPatient",
    "ImagePositionPatient",
    CAST("SliceThickness" AS FLOAT) AS "SliceThickness",
    "PixelSpacing",
    "Rows",
    "Columns",
    CAST("Exposure" AS FLOAT) AS "Exposure",
    "SOPInstanceUID",
    "instance_size"
  FROM IDC.IDC_V17.DICOM_ALL
  WHERE 
    "Modality" = 'CT'
    AND "collection_id" != 'NLST'
    AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70', '1.2.840.10008.1.2.4.51')
    AND "ImageType" NOT ILIKE '%LOCALIZER%'
),
series_filtered AS (
  SELECT 
    sd.*,
    COUNT(DISTINCT sd."ImageOrientationPatient") OVER (PARTITION BY sd."SeriesInstanceUID") AS orientation_count,
    COUNT(DISTINCT sd."PixelSpacing") OVER (PARTITION BY sd."SeriesInstanceUID") AS pixel_spacing_count,
    COUNT(DISTINCT sd."Rows") OVER (PARTITION BY sd."SeriesInstanceUID") AS rows_count,
    COUNT(DISTINCT sd."Columns") OVER (PARTITION BY sd."SeriesInstanceUID") AS columns_count,
    COUNT(DISTINCT sd."SOPInstanceUID") OVER (PARTITION BY sd."SeriesInstanceUID") AS num_instances,
    COUNT(DISTINCT sd."ImagePositionPatient") OVER (PARTITION BY sd."SeriesInstanceUID") AS num_positions
  FROM series_data sd
),
series_filtered2 AS (
  SELECT *
  FROM series_filtered
  WHERE 
    orientation_count = 1
    AND pixel_spacing_count = 1
    AND rows_count = 1
    AND columns_count = 1
    AND num_instances = num_positions
),
series_orientation AS (
  SELECT DISTINCT
    "SeriesInstanceUID",
    "SeriesNumber",
    "StudyInstanceUID",
    "PatientID",
    "ImageOrientationPatient"
  FROM series_filtered2
),
series_orientation_parsed AS (
  SELECT 
    so.*,
    CAST(so."ImageOrientationPatient"[0] AS FLOAT) AS m1,
    CAST(so."ImageOrientationPatient"[1] AS FLOAT) AS m2,
    CAST(so."ImageOrientationPatient"[2] AS FLOAT) AS m3,
    CAST(so."ImageOrientationPatient"[3] AS FLOAT) AS m4,
    CAST(so."ImageOrientationPatient"[4] AS FLOAT) AS m5,
    CAST(so."ImageOrientationPatient"[5] AS FLOAT) AS m6
  FROM series_orientation so
),
series_normal AS (
  SELECT 
    sop.*,
    ((sop.m2 * sop.m6) - (sop.m3 * sop.m5)) AS normal_x,
    ((sop.m3 * sop.m4) - (sop.m1 * sop.m6)) AS normal_y,
    ((sop.m1 * sop.m5) - (sop.m2 * sop.m4)) AS normal_z
  FROM series_orientation_parsed sop
),
series_dot_product AS (
  SELECT
    sn.*,
    ABS(
      (sn.normal_x * 0) + (sn.normal_y * 0) + (sn.normal_z * 1)
    ) AS "MaxDotProduct"
  FROM series_normal sn
),
series_instances AS (
  SELECT 
    s."SeriesInstanceUID",
    CAST(s."ImagePositionPatient"[2] AS FLOAT) AS z_position
  FROM series_filtered2 s
),
series_slice_diff AS (
  SELECT
    si."SeriesInstanceUID",
    si.z_position,
    ROW_NUMBER() OVER (PARTITION BY si."SeriesInstanceUID" ORDER BY si.z_position) AS rn
  FROM series_instances si
),
series_slice_intervals AS (
  SELECT
    s1."SeriesInstanceUID",
    s1.z_position AS z1,
    s2.z_position AS z2,
    ABS(s2.z_position - s1.z_position) AS interval_diff
  FROM series_slice_diff s1
  JOIN series_slice_diff s2
    ON s1."SeriesInstanceUID" = s2."SeriesInstanceUID" AND s1.rn = s2.rn - 1
),
series_slice_stats AS (
  SELECT
    "SeriesInstanceUID",
    MAX(interval_diff) AS "MaxSliceIntervalDiff",
    MIN(interval_diff) AS "MinSliceIntervalDiff"
  FROM series_slice_intervals
  GROUP BY "SeriesInstanceUID"
),
series_exposure AS (
  SELECT
    s."SeriesInstanceUID",
    COUNT(DISTINCT s."Exposure") AS "NumDistinctExposureValues",
    MAX(s."Exposure") AS "MaxExposureValue",
    MIN(s."Exposure") AS "MinExposureValue"
  FROM series_filtered2 s
  GROUP BY s."SeriesInstanceUID"
),
series_size AS (
  SELECT
    "SeriesInstanceUID",
    SUM("instance_size") / (1024 * 1024) AS "SeriesSizeMB",
    COUNT(*) AS "NumInstances"
  FROM series_filtered2
  GROUP BY "SeriesInstanceUID"
),
series_slice_thickness AS (
  SELECT
    s."SeriesInstanceUID",
    COUNT(DISTINCT s."SliceThickness") AS "NumDistinctSliceThickness"
  FROM series_filtered2 s
  GROUP BY s."SeriesInstanceUID"
),
final_series AS (
  SELECT
    sdp."SeriesInstanceUID",
    sdp."SeriesNumber",
    sdp."StudyInstanceUID",
    sdp."PatientID",
    ROUND(sdp."MaxDotProduct", 4) AS "MaxDotProduct",
    ss."NumInstances",
    st."NumDistinctSliceThickness",
    ROUND(sss."MaxSliceIntervalDiff", 4) AS "MaxSliceIntervalDiff",
    ROUND(sss."MinSliceIntervalDiff", 4) AS "MinSliceIntervalDiff",
    ROUND((sss."MaxSliceIntervalDiff" - sss."MinSliceIntervalDiff"), 4) AS "ToleranceSliceIntervalDiff",
    se."NumDistinctExposureValues",
    se."MaxExposureValue",
    se."MinExposureValue",
    ROUND((se."MaxExposureValue" - se."MinExposureValue"), 4) AS "ExposureRange",
    ROUND(ss."SeriesSizeMB", 4) AS "SeriesSizeMB"
  FROM series_dot_product sdp
  JOIN series_size ss ON sdp."SeriesInstanceUID" = ss."SeriesInstanceUID"
  JOIN series_slice_thickness st ON sdp."SeriesInstanceUID" = st."SeriesInstanceUID"
  LEFT JOIN series_slice_stats sss ON sdp."SeriesInstanceUID" = sss."SeriesInstanceUID"
  LEFT JOIN series_exposure se ON sdp."SeriesInstanceUID" = se."SeriesInstanceUID"
)
SELECT *
FROM final_series
WHERE ABS("MaxDotProduct" - 1) <= 0.01
ORDER BY "ToleranceSliceIntervalDiff" DESC NULLS LAST, "ExposureRange" DESC NULLS LAST, "SeriesInstanceUID" DESC;