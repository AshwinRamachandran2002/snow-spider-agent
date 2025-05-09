SELECT
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    q."findingSite":"CodeMeaning"::STRING                                         AS "FindingSiteCodeMeaning",

    ROUND(MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Elongation'
                   THEN q."Value" END), 4)                                        AS "Elongation_Max",

    ROUND(MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Flatness'
                   THEN q."Value" END), 4)                                        AS "Flatness_Max",

    ROUND(MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Least Axis in 3D Length'
                   THEN q."Value" END), 4)                                        AS "LeastAxis3DLength_Max",

    ROUND(MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Major Axis in 3D Length'
                   THEN q."Value" END), 4)                                        AS "MajorAxis3DLength_Max",

    ROUND(MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Maximum 3D Diameter of a Mesh'
                   THEN q."Value" END), 4)                                        AS "Maximum3DDiameterMesh_Max",

    ROUND(MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Minor Axis in 3D Length'
                   THEN q."Value" END), 4)                                        AS "MinorAxis3DLength_Max",

    ROUND(MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Sphericity'
                   THEN q."Value" END), 4)                                        AS "Sphericity_Max",

    ROUND(MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Surface Area of Mesh'
                   THEN q."Value" END), 4)                                        AS "SurfaceAreaMesh_Max",

    ROUND(MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Surface to Volume Ratio'
                   THEN q."Value" END), 4)                                        AS "SurfaceToVolumeRatio_Max",

    ROUND(MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Volume from Voxel Summation'
                   THEN q."Value" END), 4)                                        AS "VolumeFromVoxelSummation_Max",

    ROUND(MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Volume of Mesh'
                   THEN q."Value" END), 4)                                        AS "VolumeOfMesh_Max"

FROM   IDC.IDC_V17."DICOM_ALL"                 AS d
JOIN   IDC.IDC_V17."QUANTITATIVE_MEASUREMENTS" AS q
       ON q."segmentationInstanceUID" = d."SOPInstanceUID"

WHERE  d."StudyDate" LIKE '2001%'    -- restrict to studies performed in 2001
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

GROUP BY
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    q."findingSite":"CodeMeaning"::STRING

ORDER BY
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    "FindingSiteCodeMeaning";