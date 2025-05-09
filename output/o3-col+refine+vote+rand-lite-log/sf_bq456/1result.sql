SELECT
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    q."findingSite":"CodeMeaning"::STRING AS "FindingSiteMeaning",

    /* Maximum values of requested quantitative measurements */
    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Elongation'
             THEN q."Value"::FLOAT END) AS "Max_Elongation",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Flatness'
             THEN q."Value"::FLOAT END) AS "Max_Flatness",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Least Axis in 3D Length'
             THEN q."Value"::FLOAT END) AS "Max_LeastAxis3D",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Major Axis in 3D Length'
             THEN q."Value"::FLOAT END) AS "Max_MajorAxis3D",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Maximum 3D Diameter of a Mesh'
             THEN q."Value"::FLOAT END) AS "Max_Max3DDiameter",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Minor Axis in 3D Length'
             THEN q."Value"::FLOAT END) AS "Max_MinorAxis3D",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Sphericity'
             THEN q."Value"::FLOAT END) AS "Max_Sphericity",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Surface area of mesh'
             THEN q."Value"::FLOAT END) AS "Max_SurfaceArea",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Surface to volume ratio'
             THEN q."Value"::FLOAT END) AS "Max_SurfaceVolumeRatio",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Volume from voxel summation'
             THEN q."Value"::FLOAT END) AS "Max_VolumeVoxel",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Volume of mesh'
             THEN q."Value"::FLOAT END) AS "Max_VolumeMesh"

FROM   IDC.IDC_V17.DICOM_ALL                AS d
JOIN   IDC.IDC_V17.QUANTITATIVE_MEASUREMENTS AS q
       ON q."segmentationInstanceUID" = d."SOPInstanceUID"

WHERE  YEAR(d."StudyDate") = 2001

GROUP BY
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    q."findingSite":"CodeMeaning"::STRING;