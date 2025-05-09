SELECT
  t1."PatientID",
  t1."StudyInstanceUID",
  t1."StudyDate",
  t2."findingSite":"CodeMeaning"::STRING AS "FindingSite_CodeMeaning",
  MAX(CASE WHEN t2."Quantity":"CodeMeaning"::STRING = 'Elongation' THEN t2."Value" END) AS "Max_Elongation",
  MAX(CASE WHEN t2."Quantity":"CodeMeaning"::STRING = 'Flatness' THEN t2."Value" END) AS "Max_Flatness",
  MAX(CASE WHEN t2."Quantity":"CodeMeaning"::STRING = 'Least Axis in 3D Length' THEN t2."Value" END) AS "Max_Least_Axis_in_3D_Length",
  MAX(CASE WHEN t2."Quantity":"CodeMeaning"::STRING = 'Major Axis in 3D Length' THEN t2."Value" END) AS "Max_Major_Axis_in_3D_Length",
  MAX(CASE WHEN t2."Quantity":"CodeMeaning"::STRING = 'Maximum 3D Diameter of a Mesh' THEN t2."Value" END) AS "Max_Maximum_3D_Diameter_of_a_Mesh",
  MAX(CASE WHEN t2."Quantity":"CodeMeaning"::STRING = 'Minor Axis in 3D Length' THEN t2."Value" END) AS "Max_Minor_Axis_in_3D_Length",
  MAX(CASE WHEN t2."Quantity":"CodeMeaning"::STRING = 'Sphericity' THEN t2."Value" END) AS "Max_Sphericity",
  MAX(CASE WHEN t2."Quantity":"CodeMeaning"::STRING = 'Surface Area of Mesh' THEN t2."Value" END) AS "Max_Surface_Area_of_Mesh",
  MAX(CASE WHEN t2."Quantity":"CodeMeaning"::STRING = 'Surface to Volume Ratio' THEN t2."Value" END) AS "Max_Surface_to_Volume_Ratio",
  MAX(CASE WHEN t2."Quantity":"CodeMeaning"::STRING = 'Volume from Voxel Summation' THEN t2."Value" END) AS "Max_Volume_from_Voxel_Summation",
  MAX(CASE WHEN t2."Quantity":"CodeMeaning"::STRING = 'Volume of Mesh' THEN t2."Value" END) AS "Max_Volume_of_Mesh"
FROM
  IDC.IDC_V17.DICOM_ALL t1
JOIN 
  IDC.IDC_V17.QUANTITATIVE_MEASUREMENTS t2
ON
  t1."SOPInstanceUID" = t2."segmentationInstanceUID"
WHERE
  EXTRACT(YEAR FROM t1."StudyDate") = 2001
GROUP BY
  t1."PatientID",
  t1."StudyInstanceUID",
  t1."StudyDate",
  "FindingSite_CodeMeaning";