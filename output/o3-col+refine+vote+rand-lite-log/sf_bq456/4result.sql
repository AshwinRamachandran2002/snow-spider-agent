SELECT
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    q."findingSite":"CodeMeaning"::STRING                                           AS "FindingSite_CodeMeaning",

    /*-- maximum value of each requested quantitative measurement ‑-*/
    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'ELONGATION'                     THEN q."Value" END) AS "Max_Elongation",
    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'FLATNESS'                       THEN q."Value" END) AS "Max_Flatness",
    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'LEAST AXIS IN 3D LENGTH'        THEN q."Value" END) AS "Max_LeastAxis3D",
    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'MAJOR AXIS IN 3D LENGTH'        THEN q."Value" END) AS "Max_MajorAxis3D",
    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'MAXIMUM 3D DIAMETER OF A MESH'  THEN q."Value" END) AS "Max_Max3DDiameter",
    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'MINOR AXIS IN 3D LENGTH'        THEN q."Value" END) AS "Max_MinorAxis3D",
    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'SPHERICITY'                     THEN q."Value" END) AS "Max_Sphericity",
    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'SURFACE AREA OF MESH'           THEN q."Value" END) AS "Max_SurfaceAreaMesh",
    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'SURFACE TO VOLUME RATIO'        THEN q."Value" END) AS "Max_SurfVolRatio",
    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'VOLUME FROM VOXEL SUMMATION'    THEN q."Value" END) AS "Max_VolumeVoxelSum",
    MAX(CASE WHEN UPPER(q."Quantity":"CodeMeaning"::STRING) = 'VOLUME OF MESH'                 THEN q."Value" END) AS "Max_VolumeMesh"

FROM  "IDC"."IDC_V17"."DICOM_ALL"                 d
JOIN  "IDC"."IDC_V17"."QUANTITATIVE_MEASUREMENTS" q
      ON q."segmentationInstanceUID" = d."SOPInstanceUID"

WHERE d."StudyDate" LIKE '2001-%'

GROUP BY
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    q."findingSite":"CodeMeaning"::STRING;