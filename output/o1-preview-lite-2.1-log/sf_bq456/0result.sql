SELECT q."PatientID",
       p."StudyInstanceUID",
       p."StudyDate",
       GET(q."findingSite", 'CodeMeaning')::STRING AS "FindingSite",
       ROUND(MAX(CASE WHEN GET(q."Quantity", 'CodeMeaning')::STRING = 'Elongation' THEN q."Value" END), 4) AS "Elongation",
       ROUND(MAX(CASE WHEN GET(q."Quantity", 'CodeMeaning')::STRING = 'Flatness' THEN q."Value" END), 4) AS "Flatness",
       ROUND(MAX(CASE WHEN GET(q."Quantity", 'CodeMeaning')::STRING = 'Least Axis in 3D Length' THEN q."Value" END), 4) AS "LeastAxisIn3DLength",
       ROUND(MAX(CASE WHEN GET(q."Quantity", 'CodeMeaning')::STRING = 'Major Axis in 3D Length' THEN q."Value" END), 4) AS "MajorAxisIn3DLength",
       ROUND(MAX(CASE WHEN GET(q."Quantity", 'CodeMeaning')::STRING = 'Maximum 3D Diameter of a Mesh' THEN q."Value" END), 4) AS "Maximum3DDiameterOfMesh",
       ROUND(MAX(CASE WHEN GET(q."Quantity", 'CodeMeaning')::STRING = 'Minor Axis in 3D Length' THEN q."Value" END), 4) AS "MinorAxisIn3DLength",
       ROUND(MAX(CASE WHEN GET(q."Quantity", 'CodeMeaning')::STRING = 'Sphericity' THEN q."Value" END), 4) AS "Sphericity",
       ROUND(MAX(CASE WHEN GET(q."Quantity", 'CodeMeaning')::STRING = 'Surface Area of Mesh' THEN q."Value" END), 4) AS "SurfaceAreaOfMesh",
       ROUND(MAX(CASE WHEN GET(q."Quantity", 'CodeMeaning')::STRING = 'Surface to Volume Ratio' THEN q."Value" END), 4) AS "SurfaceToVolumeRatio",
       ROUND(MAX(CASE WHEN GET(q."Quantity", 'CodeMeaning')::STRING = 'Volume from Voxel Summation' THEN q."Value" END), 4) AS "VolumeFromVoxelSummation",
       ROUND(MAX(CASE WHEN GET(q."Quantity", 'CodeMeaning')::STRING = 'Volume of Mesh' THEN q."Value" END), 4) AS "VolumeOfMesh"
FROM "IDC"."IDC_V17"."QUANTITATIVE_MEASUREMENTS" q
JOIN "IDC"."IDC_V17"."DICOM_PIVOT" p
  ON q."SOPInstanceUID" = p."SOPInstanceUID"
WHERE p."StudyDate" >= '2001-01-01' AND p."StudyDate" < '2002-01-01'
GROUP BY q."PatientID", p."StudyInstanceUID", p."StudyDate", GET(q."findingSite", 'CodeMeaning')::STRING;