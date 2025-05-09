SELECT
    D."PatientID",
    D."StudyInstanceUID",
    D."StudyDate",
    Q."findingSite":"CodeMeaning"::STRING  AS "FindingSite_CodeMeaning",

    MAX(CASE WHEN Q."Quantity":"CodeMeaning"::STRING = 'Elongation'                      THEN Q."Value" END) AS "Max_Elongation",
    MAX(CASE WHEN Q."Quantity":"CodeMeaning"::STRING = 'Flatness'                        THEN Q."Value" END) AS "Max_Flatness",
    MAX(CASE WHEN Q."Quantity":"CodeMeaning"::STRING = 'Least Axis in 3D Length'         THEN Q."Value" END) AS "Max_LeastAxis3DLength",
    MAX(CASE WHEN Q."Quantity":"CodeMeaning"::STRING = 'Major Axis in 3D Length'         THEN Q."Value" END) AS "Max_MajorAxis3DLength",
    MAX(CASE WHEN Q."Quantity":"CodeMeaning"::STRING = 'Maximum 3D Diameter of a Mesh'   THEN Q."Value" END) AS "Max_Max3DDiameterMesh",
    MAX(CASE WHEN Q."Quantity":"CodeMeaning"::STRING = 'Minor Axis in 3D Length'         THEN Q."Value" END) AS "Max_MinorAxis3DLength",
    MAX(CASE WHEN Q."Quantity":"CodeMeaning"::STRING = 'Sphericity'                      THEN Q."Value" END) AS "Max_Sphericity",
    MAX(CASE WHEN Q."Quantity":"CodeMeaning"::STRING = 'Surface area of mesh'            THEN Q."Value" END) AS "Max_SurfaceAreaMesh",
    MAX(CASE WHEN Q."Quantity":"CodeMeaning"::STRING = 'Surface to volume ratio'         THEN Q."Value" END) AS "Max_SurfaceToVolumeRatio",
    MAX(CASE WHEN Q."Quantity":"CodeMeaning"::STRING = 'Volume from voxel summation'     THEN Q."Value" END) AS "Max_VolumeFromVoxelSummation",
    MAX(CASE WHEN Q."Quantity":"CodeMeaning"::STRING = 'Volume of mesh'                  THEN Q."Value" END) AS "Max_VolumeOfMesh"

FROM
    IDC.IDC_V17."DICOM_ALL"                AS D
JOIN
    IDC.IDC_V17."QUANTITATIVE_MEASUREMENTS" AS Q
      ON Q."segmentationInstanceUID" = D."SOPInstanceUID"

WHERE
    YEAR(D."StudyDate") = 2001

GROUP BY
    D."PatientID",
    D."StudyInstanceUID",
    D."StudyDate",
    Q."findingSite":"CodeMeaning"::STRING;