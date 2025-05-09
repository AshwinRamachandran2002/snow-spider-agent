SELECT
       d."PatientID",
       d."StudyInstanceUID",
       d."StudyDate",
       q."findingSite":"CodeMeaning"::STRING                                        AS "FindingSiteCodeMeaning",

       MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Elongation'
                THEN ROUND(q."Value", 4) END)                                       AS "Elongation_Max",
       MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Flatness'
                THEN ROUND(q."Value", 4) END)                                       AS "Flatness_Max",
       MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Least Axis in 3D Length'
                THEN ROUND(q."Value", 4) END)                                       AS "LeastAxis3DLength_Max",
       MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Major Axis in 3D Length'
                THEN ROUND(q."Value", 4) END)                                       AS "MajorAxis3DLength_Max",
       MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Maximum 3D Diameter of a Mesh'
                THEN ROUND(q."Value", 4) END)                                       AS "Maximum3DDiameterMesh_Max",
       MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Minor Axis in 3D Length'
                THEN ROUND(q."Value", 4) END)                                       AS "MinorAxis3DLength_Max",
       MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Sphericity'
                THEN ROUND(q."Value", 4) END)                                       AS "Sphericity_Max",
       MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Surface Area of Mesh'
                THEN ROUND(q."Value", 4) END)                                       AS "SurfaceAreaMesh_Max",
       MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Surface to Volume Ratio'
                THEN ROUND(q."Value", 4) END)                                       AS "SurfaceToVolumeRatio_Max",
       MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Volume from Voxel Summation'
                THEN ROUND(q."Value", 4) END)                                       AS "VolumeFromVoxelSummation_Max",
       MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Volume of Mesh'
                THEN ROUND(q."Value", 4) END)                                       AS "VolumeOfMesh_Max"

FROM   IDC.IDC_V17.DICOM_ALL                 d
JOIN   IDC.IDC_V17.QUANTITATIVE_MEASUREMENTS q
       ON q."segmentationInstanceUID" = d."SOPInstanceUID"

WHERE  d."StudyDate" BETWEEN '2001-01-01' AND '2001-12-31'
  AND  q."Quantity":"CodeMeaning"::STRING IN (
          'Elongation',
          'Flatness',
          'Least Axis in 3D Length',
          'Major Axis in 3D Length',
          'Maximum 3D Diameter of a Mesh',
          'Minor Axis in 3D Length',
          'Sphericity',
          'Surface Area of Mesh',
          'Surface to Volume Ratio',
          'Volume from Voxel Summation',
          'Volume of Mesh'
       )

GROUP  BY
       d."PatientID",
       d."StudyInstanceUID",
       d."StudyDate",
       q."findingSite":"CodeMeaning"::STRING

ORDER BY
       d."PatientID",
       d."StudyInstanceUID",
       d."StudyDate",
       "FindingSiteCodeMeaning";