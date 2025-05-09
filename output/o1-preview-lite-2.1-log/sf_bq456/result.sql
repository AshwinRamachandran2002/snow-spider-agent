SELECT
  qm."PatientID",
  dp."StudyInstanceUID",
  dp."StudyDate",
  qm."findingSite":"CodeMeaning"::STRING AS "FindingSite",
  ROUND(MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'elongation' THEN qm."Value" END), 4) AS "Elongation",
  ROUND(MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'flatness' THEN qm."Value" END), 4) AS "Flatness",
  ROUND(MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'least axis in 3d length' THEN qm."Value" END), 4) AS "LeastAxisIn3DLength",
  ROUND(MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'major axis in 3d length' THEN qm."Value" END), 4) AS "MajorAxisIn3DLength",
  ROUND(MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'maximum 3d diameter of a mesh' THEN qm."Value" END), 4) AS "Maximum3DDiameterOfMesh",
  ROUND(MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'minor axis in 3d length' THEN qm."Value" END), 4) AS "MinorAxisIn3DLength",
  ROUND(MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'sphericity' THEN qm."Value" END), 4) AS "Sphericity",
  ROUND(MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'surface area of mesh' THEN qm."Value" END), 4) AS "SurfaceAreaOfMesh",
  ROUND(MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'surface to volume ratio' THEN qm."Value" END), 4) AS "SurfaceToVolumeRatio",
  ROUND(MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'volume from voxel summation' THEN qm."Value" END), 4) AS "VolumeFromVoxelSummation",
  ROUND(MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'volume of mesh' THEN qm."Value" END), 4) AS "VolumeOfMesh"
FROM IDC.IDC_V17."QUANTITATIVE_MEASUREMENTS" AS qm
JOIN IDC.IDC_V17."DICOM_PIVOT" AS dp
  ON qm."SOPInstanceUID" = dp."SOPInstanceUID"
WHERE dp."StudyDate" >= '2001-01-01' AND dp."StudyDate" < '2002-01-01'
GROUP BY 
  qm."PatientID", dp."StudyInstanceUID", dp."StudyDate", qm."findingSite":"CodeMeaning"::STRING
ORDER BY 
  qm."PatientID", dp."StudyInstanceUID";