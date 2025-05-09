SELECT
  da."PatientID",
  da."StudyInstanceUID",
  da."StudyDate",
  qm."findingSite":"CodeMeaning"::STRING AS "FindingSite_CodeMeaning",
  MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Elongation' THEN qm."Value" END) AS "Max_Elongation",
  MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Flatness' THEN qm."Value" END) AS "Max_Flatness",
  MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Least Axis in 3D Length' THEN qm."Value" END) AS "Max_Least_Axis_in_3D_Length",
  MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Major Axis in 3D Length' THEN qm."Value" END) AS "Max_Major_Axis_in_3D_Length",
  MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Maximum 3D Diameter of a Mesh' THEN qm."Value" END) AS "Max_Maximum_3D_Diameter_of_a_Mesh",
  MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Minor Axis in 3D Length' THEN qm."Value" END) AS "Max_Minor_Axis_in_3D_Length",
  MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Sphericity' THEN qm."Value" END) AS "Max_Sphericity",
  MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Surface Area of Mesh' THEN qm."Value" END) AS "Max_Surface_Area_of_Mesh",
  MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Surface to Volume Ratio' THEN qm."Value" END) AS "Max_Surface_to_Volume_Ratio",
  MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Volume from Voxel Summation' THEN qm."Value" END) AS "Max_Volume_from_Voxel_Summation",
  MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Volume of Mesh' THEN qm."Value" END) AS "Max_Volume_of_Mesh"
FROM IDC.IDC_V17."DICOM_ALL" AS da
JOIN IDC.IDC_V17."QUANTITATIVE_MEASUREMENTS" AS qm
  ON da."SOPInstanceUID" = qm."segmentationInstanceUID"
WHERE
  da."StudyDate" BETWEEN '2001-01-01' AND '2001-12-31'
GROUP BY
  da."PatientID",
  da."StudyInstanceUID",
  da."StudyDate",
  qm."findingSite":"CodeMeaning"::STRING
ORDER BY
  da."PatientID",
  da."StudyInstanceUID",
  da."StudyDate",
  qm."findingSite":"CodeMeaning"::STRING;