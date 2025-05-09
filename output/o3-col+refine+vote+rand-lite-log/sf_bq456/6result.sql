SELECT
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    q."findingSite":"CodeMeaning"::STRING                                                   AS "FindingSite_CodeMeaning",

    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING ILIKE '%Elongation%'                     THEN q."Value" END) AS "Elongation_Max",
    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING ILIKE '%Flatness%'                       THEN q."Value" END) AS "Flatness_Max",
    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING ILIKE '%Least Axis in 3D Length%'        THEN q."Value" END) AS "LeastAxis3D_Max",
    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING ILIKE '%Major Axis in 3D Length%'        THEN q."Value" END) AS "MajorAxis3D_Max",
    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING ILIKE '%Maximum 3D Diameter of a Mesh%'  THEN q."Value" END) AS "Max3DDiamMesh_Max",
    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING ILIKE '%Minor Axis in 3D Length%'        THEN q."Value" END) AS "MinorAxis3D_Max",
    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING ILIKE '%Sphericity%'                     THEN q."Value" END) AS "Sphericity_Max",
    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING ILIKE '%Surface Area of Mesh%'           THEN q."Value" END) AS "SurfaceAreaMesh_Max",
    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING ILIKE '%Surface to Volume Ratio%'        THEN q."Value" END) AS "SurfVolRatio_Max",
    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING ILIKE '%Volume from Voxel Summation%'    THEN q."Value" END) AS "VolumeVoxelSum_Max",
    MAX(CASE WHEN q."Quantity":"CodeMeaning"::STRING ILIKE '%Volume of Mesh%'                 THEN q."Value" END) AS "VolumeMesh_Max"

FROM  IDC.IDC_V17."DICOM_ALL"               d
JOIN  IDC.IDC_V17."QUANTITATIVE_MEASUREMENTS" q
      ON q."segmentationInstanceUID" = d."SOPInstanceUID"

WHERE d."StudyDate" BETWEEN '2001-01-01' AND '2001-12-31'

GROUP BY
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    q."findingSite":"CodeMeaning"::STRING;