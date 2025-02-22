-- Task: Considering only CT images from the 'nlst' collection, compute for each patient the difference between the maximum and minimum unique slice intervals within their series (i.e., the slice interval difference tolerance).
WITH
  nonLocalizerRawData AS (
    SELECT
      "SeriesInstanceUID",
      "PatientID",
      LEAD(TRY_CAST(axes.VALUE::STRING AS FLOAT)) OVER (
        PARTITION BY "SeriesInstanceUID" 
        ORDER BY TRY_CAST(axes.VALUE::STRING AS FLOAT)
      ) - TRY_CAST(axes.VALUE::STRING AS FLOAT) AS "slice_interval"
    FROM
      "IDC"."IDC_V17"."DICOM_ALL" AS "bid",
      LATERAL FLATTEN(input => "bid"."ImagePositionPatient") AS axes
    WHERE
      "collection_id" = 'nlst' 
      AND "Modality" = 'CT'
  ),
  geometryChecks AS (
    SELECT
      "SeriesInstanceUID",
      "PatientID",
      ARRAY_AGG(DISTINCT "slice_interval") AS "sliceIntervalDifferences"
    FROM
      nonLocalizerRawData
    GROUP BY
      "SeriesInstanceUID", 
      "PatientID"
  ),
  patientMetrics AS (
    SELECT
      "PatientID",
      MAX(TRY_CAST(sid.VALUE::STRING AS FLOAT)) AS "maxSliceIntervalDifference",
      MIN(TRY_CAST(sid.VALUE::STRING AS FLOAT)) AS "minSliceIntervalDifference",
      MAX(TRY_CAST(sid.VALUE::STRING AS FLOAT)) - MIN(TRY_CAST(sid.VALUE::STRING AS FLOAT)) AS "sliceIntervalDifferenceTolerance"
    FROM
      geometryChecks,
      LATERAL FLATTEN(input => "sliceIntervalDifferences") AS sid
    WHERE
      sid.VALUE IS NOT NULL
    GROUP BY
      "PatientID"
  )
SELECT
  "PatientID",
  "sliceIntervalDifferenceTolerance"
FROM
  patientMetrics;