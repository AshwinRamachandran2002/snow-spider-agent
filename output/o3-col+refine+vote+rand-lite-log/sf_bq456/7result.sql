SELECT
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    q."findingSite":"CodeMeaning"::STRING AS "FindingSite_CodeMeaning",

    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'ELONGATION'
             THEN q."Value" END) AS "Elongation",

    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'FLATNESS'
             THEN q."Value" END) AS "Flatness",

    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'LEAST AXIS IN 3D LENGTH'
             THEN q."Value" END) AS "Least_Axis_3D_Length",

    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'MAJOR AXIS IN 3D LENGTH'
             THEN q."Value" END) AS "Major_Axis_3D_Length",

    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'MAXIMUM 3D DIAMETER OF A MESH'
             THEN q."Value" END) AS "Max_3D_Diameter_Mesh",

    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'MINOR AXIS IN 3D LENGTH'
             THEN q."Value" END) AS "Minor_Axis_3D_Length",

    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'SPHERICITY'
             THEN q."Value" END) AS "Sphericity",

    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'SURFACE AREA OF MESH'
             THEN q."Value" END) AS "Surface_Area_Mesh",

    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'SURFACE TO VOLUME RATIO'
             THEN q."Value" END) AS "Surface_to_Volume_Ratio",

    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'VOLUME FROM VOXEL SUMMATION'
             THEN q."Value" END) AS "Volume_from_Voxel_Summation",

    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'VOLUME OF MESH'
             THEN q."Value" END) AS "Volume_of_Mesh"

FROM   IDC.IDC_V17.DICOM_ALL                 d
JOIN   IDC.IDC_V17.QUANTITATIVE_MEASUREMENTS q
       ON q."segmentationInstanceUID" = d."SOPInstanceUID"
WHERE  YEAR(d."StudyDate") = 2001
  AND  UPPER(q."Quantity":"CodeMeaning"::STRING) IN (
        'ELONGATION',
        'FLATNESS',
        'LEAST AXIS IN 3D LENGTH',
        'MAJOR AXIS IN 3D LENGTH',
        'MAXIMUM 3D DIAMETER OF A MESH',
        'MINOR AXIS IN 3D LENGTH',
        'SPHERICITY',
        'SURFACE AREA OF MESH',
        'SURFACE TO VOLUME RATIO',
        'VOLUME FROM VOXEL SUMMATION',
        'VOLUME OF MESH'
      )
GROUP BY
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    q."findingSite":"CodeMeaning"::STRING;