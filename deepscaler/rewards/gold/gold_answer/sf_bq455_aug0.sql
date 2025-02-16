-- Task: Identify the top five CT scan series by their size in MiB, including their SeriesInstanceUID, series number, patient ID, and series size. The series must satisfy the following conditions:
-- - The series must be from the 'CT' modality and not from the 'nlst' collection.
-- - Exclude any series where the ImageType is 'LOCALIZER' or where the TransferSyntaxUID is either '1.2.840.10008.1.2.4.70' or '1.2.840.10008.1.2.4.51' (i.e., JPEG compressed).
-- - The series must have only one unique ImageOrientationPatient value.
-- - The series must have only one unique PixelSpacing value.
-- - Each series must have the number of images equal to the number of unique z-axis positions (no duplicate slices).
-- - Each series must have only one unique xyImagePosition value.
-- - The pixel dimensions (Rows and Columns) must be consistent within each series (only one unique value for each).
-- - The absolute value of the z-axis component of the cross product of the x and y direction cosines from ImageOrientationPatient must be between 0.99 and 1.01, ensuring alignment with the expected imaging plane.

WITH
  -- Create a common table expression (CTE) named localizerAndJpegCompressedSeries
  localizerAndJpegCompressedSeries AS (
    SELECT 
      "SeriesInstanceUID"
    FROM 
      IDC.IDC_V17."DICOM_ALL" AS bid
    WHERE 
      "ImageType" = 'LOCALIZER' OR
      "TransferSyntaxUID" IN ('1.2.840.10008.1.2.4.70', '1.2.840.10008.1.2.4.51')
  ),
  
  -- Create a common table expression (CTE) for x_vector calculation (first three elements)
  imageOrientation AS (
    SELECT
      "SeriesInstanceUID",
      ARRAY_AGG(CAST(part.value AS FLOAT)) AS "x_vector"
    FROM 
      IDC.IDC_V17."DICOM_ALL" AS bid,
      LATERAL FLATTEN(input => bid."ImageOrientationPatient") AS part
    WHERE
      part.index BETWEEN 0 AND 2
    GROUP BY "SeriesInstanceUID"
  ),
  
  -- Create a common table expression (CTE) for y_vector calculation (next three elements)
  imageOrientationY AS (
    SELECT
      "SeriesInstanceUID",
      ARRAY_AGG(CAST(part.value AS FLOAT)) AS "y_vector"
    FROM 
      IDC.IDC_V17."DICOM_ALL" AS bid,
      LATERAL FLATTEN(input => bid."ImageOrientationPatient") AS part
    WHERE
      part.index BETWEEN 3 AND 5
    GROUP BY "SeriesInstanceUID"
  ),
  
  -- Create a common table expression (CTE) named nonLocalizerRawData
  nonLocalizerRawData AS (
    SELECT
      bid."SeriesInstanceUID",
      bid."StudyInstanceUID",
      bid."PatientID",
      bid."SOPInstanceUID",
      bid."SliceThickness",
      bid."ImageType",
      bid."TransferSyntaxUID",
      bid."SeriesNumber",
      bid."aws_bucket",
      bid."crdc_series_uuid",
      CAST(bid."Exposure" AS FLOAT) AS "Exposure",
      CAST(ipp.value AS FLOAT) AS "zImagePosition",
      CONCAT(ipp2.value, '/', ipp3.value) AS "xyImagePosition",
      LEAD(CAST(ipp.value AS FLOAT)) OVER (PARTITION BY bid."SeriesInstanceUID" ORDER BY CAST(ipp.value AS FLOAT)) - CAST(ipp.value AS FLOAT) AS "slice_interval",
      ARRAY_TO_STRING(bid."ImageOrientationPatient", '/') AS "iop",
      bid."PixelSpacing",
      bid."Rows" AS "pixelRows",
      bid."Columns" AS "pixelColumns",
      bid."instance_size" AS "instanceSize"
    FROM
      IDC.IDC_V17."DICOM_ALL" AS bid
    LEFT JOIN LATERAL FLATTEN(input => bid."ImagePositionPatient") AS ipp
    LEFT JOIN LATERAL FLATTEN(input => bid."ImagePositionPatient") AS ipp2
    LEFT JOIN LATERAL FLATTEN(input => bid."ImagePositionPatient") AS ipp3
    WHERE
      bid."collection_id" != 'nlst'
      AND bid."Modality" = 'CT'
      AND ipp.index = 2
      AND ipp2.index = 0
      AND ipp3.index = 1
      AND bid."SeriesInstanceUID" NOT IN (SELECT "SeriesInstanceUID" FROM localizerAndJpegCompressedSeries)
  ),
  
  -- Cross product calculation
  crossProduct AS (
    SELECT
      nld."SOPInstanceUID",
      nld."SeriesInstanceUID",
      OBJECT_CONSTRUCT(
        'x', ("x_vector"[1] * "y_vector"[2] - "x_vector"[2] * "y_vector"[1]),
        'y', ("x_vector"[2] * "y_vector"[0] - "x_vector"[0] * "y_vector"[2]),
        'z', ("x_vector"[0] * "y_vector"[1] - "x_vector"[1] * "y_vector"[0])
      ) AS "xyCrossProduct"
    FROM 
      nonLocalizerRawData AS nld
    JOIN imageOrientation AS io ON nld."SeriesInstanceUID" = io."SeriesInstanceUID"
    JOIN imageOrientationY AS ioy ON nld."SeriesInstanceUID" = ioy."SeriesInstanceUID"
  ),
  
  -- Cross product elements extraction and row numbering
  crossProductElements AS (
    SELECT
      cp."SOPInstanceUID",  
      cp."SeriesInstanceUID",  
      elem.value,
      ROW_NUMBER() OVER (PARTITION BY cp."SOPInstanceUID", cp."SeriesInstanceUID" ORDER BY elem.value) AS rn
    FROM 
      crossProduct AS cp
    JOIN LATERAL FLATTEN(input => ARRAY_CONSTRUCT(
        cp."xyCrossProduct"['x'],
        cp."xyCrossProduct"['y'],
        cp."xyCrossProduct"['z']
      )) AS elem
  ),
  
  -- Dot product calculation
  dotProduct AS (
    SELECT
      cpe."SOPInstanceUID",  
      cpe."SeriesInstanceUID",  
      SUM(
        CASE 
          WHEN cpe.rn = 1 THEN cpe.value * 0  -- x * 0
          WHEN cpe.rn = 2 THEN cpe.value * 0  -- y * 0
          WHEN cpe.rn = 3 THEN cpe.value * 1  -- z * 1
        END
      ) AS "xyDotProduct"
    FROM 
      crossProductElements AS cpe
    GROUP BY 
      cpe."SOPInstanceUID",  
      cpe."SeriesInstanceUID"
  ),
  
  -- Geometry checks for series consistency
  geometryChecks AS (
    SELECT
      gc."SeriesInstanceUID",
      gc."SeriesNumber",
      gc."aws_bucket",
      gc."crdc_series_uuid",
      gc."StudyInstanceUID",
      gc."PatientID",
      ARRAY_AGG(DISTINCT gc."slice_interval") AS "sliceIntervalDifferences",
      ARRAY_AGG(DISTINCT gc."Exposure") AS "distinctExposures",
      COUNT(DISTINCT gc."iop") AS "iopCount",
      COUNT(DISTINCT gc."PixelSpacing") AS "pixelSpacingCount",
      COUNT(DISTINCT gc."zImagePosition") AS "positionCount",
      COUNT(DISTINCT gc."xyImagePosition") AS "xyPositionCount",
      COUNT(DISTINCT gc."SOPInstanceUID") AS "sopInstanceCount",
      COUNT(DISTINCT gc."SliceThickness") AS "sliceThicknessCount",
      COUNT(DISTINCT gc."Exposure") AS "exposureCount",
      COUNT(DISTINCT gc."pixelRows") AS "pixelRowCount",
      COUNT(DISTINCT gc."pixelColumns") AS "pixelColumnCount",
      dp."xyDotProduct",
      SUM(gc."instanceSize") / 1024 / 1024 AS "seriesSizeInMiB"
    FROM 
      nonLocalizerRawData AS gc
    JOIN dotProduct AS dp ON gc."SeriesInstanceUID" = dp."SeriesInstanceUID" 
      AND gc."SOPInstanceUID" = dp."SOPInstanceUID"
    GROUP BY
      gc."SeriesInstanceUID", 
      gc."SeriesNumber",
      gc."aws_bucket",
      gc."crdc_series_uuid",
      gc."StudyInstanceUID",
      gc."PatientID",
      dp."xyDotProduct"
    HAVING
      COUNT(DISTINCT gc."iop") = 1 
      AND COUNT(DISTINCT gc."PixelSpacing") = 1  
      AND COUNT(DISTINCT gc."SOPInstanceUID") = COUNT(DISTINCT gc."zImagePosition") 
      AND COUNT(DISTINCT gc."xyImagePosition") = 1
      AND COUNT(DISTINCT gc."pixelRows") = 1 
      AND COUNT(DISTINCT gc."pixelColumns") = 1 
      AND ABS(dp."xyDotProduct") BETWEEN 0.99 AND 1.01
  )

SELECT
  geometryChecks."SeriesInstanceUID",
  geometryChecks."SeriesNumber",
  geometryChecks."PatientID",
  geometryChecks."seriesSizeInMiB"
FROM
  geometryChecks
ORDER BY
  geometryChecks."seriesSizeInMiB" DESC
LIMIT 5;