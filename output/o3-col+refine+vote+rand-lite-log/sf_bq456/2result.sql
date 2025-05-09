SELECT
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    q."findingSite":"CodeMeaning"::STRING                           AS "FindingSite_CodeMeaning",

    /* ---- maximum of each requested quantitative measurement ---- */
    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Elongation'
             THEN q."Value" END)                                   AS "Max_Elongation",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Flatness'
             THEN q."Value" END)                                   AS "Max_Flatness",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Least Axis in 3D Length'
             THEN q."Value" END)                                   AS "Max_LeastAxis3D",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Major Axis in 3D Length'
             THEN q."Value" END)                                   AS "Max_MajorAxis3D",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Maximum 3D Diameter of a Mesh'
             THEN q."Value" END)                                   AS "Max_Max3DDiameter",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Minor Axis in 3D Length'
             THEN q."Value" END)                                   AS "Max_MinorAxis3D",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING = 'Sphericity'
             THEN q."Value" END)                                   AS "Max_Sphericity",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING IN ('Surface Area of Mesh',
                                                         'Surface area of mesh')
             THEN q."Value" END)                                   AS "Max_SurfaceArea",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING IN ('Surface to Volume Ratio',
                                                         'Surface to volume ratio')
             THEN q."Value" END)                                   AS "Max_SurfaceToVolRatio",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING IN ('Volume from Voxel Summation',
                                                         'Volume from voxel summation')
             THEN q."Value" END)                                   AS "Max_VolumeVoxelSum",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING IN ('Volume of Mesh',
                                                         'Volume of mesh')
             THEN q."Value" END)                                   AS "Max_VolumeMesh"

FROM IDC.IDC_V17."DICOM_ALL"                d
JOIN IDC.IDC_V17."QUANTITATIVE_MEASUREMENTS" q
     ON q."segmentationInstanceUID" = d."SOPInstanceUID"

WHERE d."StudyDate" BETWEEN '2001-01-01' AND '2001-12-31'

GROUP BY
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    q."findingSite":"CodeMeaning"::STRING;