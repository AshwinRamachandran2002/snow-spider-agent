SELECT
    da."PatientID",
    da."StudyInstanceUID",
    da."StudyDate",
    qm."findingSite":"CodeMeaning"::STRING                                             AS "FindingSite_CodeMeaning",

    /* maximal value of each requested measurement */
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'elongation'                          THEN qm."Value" END) AS "Max_Elongation",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'flatness'                            THEN qm."Value" END) AS "Max_Flatness",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'least axis in 3d length'             THEN qm."Value" END) AS "Max_LeastAxis3D_Length",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'major axis in 3d length'             THEN qm."Value" END) AS "Max_MajorAxis3D_Length",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'maximum 3d diameter of a mesh'       THEN qm."Value" END) AS "Max_Max3DDiameter_Mesh",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'minor axis in 3d length'             THEN qm."Value" END) AS "Max_MinorAxis3D_Length",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'sphericity'                          THEN qm."Value" END) AS "Max_Sphericity",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'surface area of mesh'                THEN qm."Value" END) AS "Max_SurfaceArea_Mesh",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'surface to volume ratio'             THEN qm."Value" END) AS "Max_SurfaceToVolumeRatio",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'volume from voxel summation'         THEN qm."Value" END) AS "Max_Volume_VoxelSummation",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::STRING) = 'volume of mesh'                      THEN qm."Value" END) AS "Max_Volume_Mesh"

FROM "IDC"."IDC_V17"."DICOM_ALL"                da
JOIN "IDC"."IDC_V17"."QUANTITATIVE_MEASUREMENTS" qm
      ON da."SOPInstanceUID" = qm."segmentationInstanceUID"

WHERE da."StudyDate" LIKE '2001%'

GROUP BY
    da."PatientID",
    da."StudyInstanceUID",
    da."StudyDate",
    qm."findingSite":"CodeMeaning"::STRING;