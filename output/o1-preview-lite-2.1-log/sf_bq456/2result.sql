SELECT
  qm."PatientID",
  dp."StudyInstanceUID",
  dp."StudyDate",
  qm."findingSite":CodeMeaning::STRING AS "FindingSite",
  ROUND(MAX(CASE WHEN qm."Quantity":CodeMeaning::STRING = 'Elongation' THEN qm."Value" END), 4) AS "Elongation",
  ROUND(MAX(CASE WHEN qm."Quantity":CodeMeaning::STRING = 'Flatness' THEN qm."Value" END), 4) AS "Flatness",
  ROUND(MAX(CASE WHEN qm."Quantity":CodeMeaning::STRING = 'Least Axis in 3D Length' THEN qm."Value" END), 4) AS "LeastAxisIn3DLength",
  ROUND(MAX(CASE WHEN qm."Quantity":CodeMeaning::STRING = 'Major Axis in 3D Length' THEN qm."Value" END), 4) AS "MajorAxisIn3DLength",
  ROUND(MAX(CASE WHEN qm."Quantity":CodeMeaning::STRING = 'Maximum 3D Diameter of a Mesh' THEN qm."Value" END), 4) AS "Maximum3DDiameterOfMesh",
  ROUND(MAX(CASE WHEN qm."Quantity":CodeMeaning::STRING = 'Minor Axis in 3D Length' THEN qm."Value" END), 4) AS "MinorAxisIn3DLength",
  ROUND(MAX(CASE WHEN qm."Quantity":CodeMeaning::STRING = 'Sphericity' THEN qm."Value" END), 4) AS "Sphericity",
  ROUND(MAX(CASE WHEN qm."Quantity":CodeMeaning::STRING = 'Surface Area of Mesh' THEN qm."Value" END), 4) AS "SurfaceAreaOfMesh",
  ROUND(MAX(CASE WHEN qm."Quantity":CodeMeaning::STRING = 'Surface to Volume Ratio' THEN qm."Value" END), 4) AS "SurfaceToVolumeRatio",
  ROUND(MAX(CASE WHEN qm."Quantity":CodeMeaning::STRING = 'Volume from Voxel Summation' THEN qm."Value" END), 4) AS "VolumeFromVoxelSummation",
  ROUND(MAX(CASE WHEN qm."Quantity":CodeMeaning::STRING = 'Volume of Mesh' THEN qm."Value" END), 4) AS "VolumeOfMesh"
FROM
  "IDC"."IDC_V17"."QUANTITATIVE_MEASUREMENTS" AS qm
JOIN
  "IDC"."IDC_V17"."DICOM_PIVOT" AS dp
  ON qm."PatientID" = dp."PatientID"
WHERE
  dp."StudyDate" BETWEEN '2001-01-01' AND '2001-12-31'
GROUP BY
  qm."PatientID",
  dp."StudyInstanceUID",
  dp."StudyDate",
  qm."findingSite":CodeMeaning::STRING;