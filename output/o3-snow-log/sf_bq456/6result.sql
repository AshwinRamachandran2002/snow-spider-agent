SELECT
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    /* CodeMeaning of the Finding Site */
    qm."findingSite":"CodeMeaning"::STRING                                            AS "FindingSite_CodeMeaning",

    /* maximum of each requested quantitative measurement */
    MAX(CASE 
            WHEN UPPER(qm."Quantity":"CodeMeaning"::STRING) = 'ELONGATION'
            THEN qm."Value"
        END)                                                                          AS "Max_Elongation",

    MAX(CASE 
            WHEN UPPER(qm."Quantity":"CodeMeaning"::STRING) = 'FLATNESS'
            THEN qm."Value"
        END)                                                                          AS "Max_Flatness",

    MAX(CASE 
            WHEN UPPER(qm."Quantity":"CodeMeaning"::STRING) = 'LEAST AXIS IN 3D LENGTH'
            THEN qm."Value"
        END)                                                                          AS "Max_LeastAxis_3D_Length",

    MAX(CASE 
            WHEN UPPER(qm."Quantity":"CodeMeaning"::STRING) = 'MAJOR AXIS IN 3D LENGTH'
            THEN qm."Value"
        END)                                                                          AS "Max_MajorAxis_3D_Length",

    MAX(CASE 
            WHEN UPPER(qm."Quantity":"CodeMeaning"::STRING) = 'MAXIMUM 3D DIAMETER OF A MESH'
            THEN qm."Value"
        END)                                                                          AS "Max_Max3D_Diameter_Mesh",

    MAX(CASE 
            WHEN UPPER(qm."Quantity":"CodeMeaning"::STRING) = 'MINOR AXIS IN 3D LENGTH'
            THEN qm."Value"
        END)                                                                          AS "Max_MinorAxis_3D_Length",

    MAX(CASE 
            WHEN UPPER(qm."Quantity":"CodeMeaning"::STRING) = 'SPHERICITY'
            THEN qm."Value"
        END)                                                                          AS "Max_Sphericity",

    MAX(CASE 
            WHEN UPPER(qm."Quantity":"CodeMeaning"::STRING) = 'SURFACE AREA OF MESH'
            THEN qm."Value"
        END)                                                                          AS "Max_SurfaceArea_Mesh",

    MAX(CASE 
            WHEN UPPER(qm."Quantity":"CodeMeaning"::STRING) = 'SURFACE TO VOLUME RATIO'
            THEN qm."Value"
        END)                                                                          AS "Max_SurfaceToVolume_Ratio",

    MAX(CASE 
            WHEN UPPER(qm."Quantity":"CodeMeaning"::STRING) = 'VOLUME FROM VOXEL SUMMATION'
            THEN qm."Value"
        END)                                                                          AS "Max_Volume_VoxelSummation",

    MAX(CASE 
            WHEN UPPER(qm."Quantity":"CodeMeaning"::STRING) = 'VOLUME OF MESH'
            THEN qm."Value"
        END)                                                                          AS "Max_Volume_Mesh"

FROM
    IDC.IDC_V17."DICOM_ALL"                    AS d
JOIN
    IDC.IDC_V17."QUANTITATIVE_MEASUREMENTS"    AS qm
      ON qm."segmentationInstanceUID" = d."SOPInstanceUID"

/* restrict to studies performed in calendar year 2001 */
WHERE
    EXTRACT(YEAR FROM d."StudyDate") = 2001

GROUP BY
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    qm."findingSite":"CodeMeaning"::STRING

ORDER BY
    d."PatientID" ASC NULLS LAST;