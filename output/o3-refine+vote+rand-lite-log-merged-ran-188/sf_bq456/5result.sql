SELECT
    da."PatientID",
    da."StudyInstanceUID",
    da."StudyDate",
    qm."findingSite":"CodeMeaning"::string                           AS "FindingSite_CodeMeaning",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Elongation'                      THEN qm."Value" END) AS "Max_Elongation",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Flatness'                        THEN qm."Value" END) AS "Max_Flatness",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Least Axis in 3D Length'         THEN qm."Value" END) AS "Max_LeastAxis3DLength",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Major Axis in 3D Length'         THEN qm."Value" END) AS "Max_MajorAxis3DLength",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Maximum 3D Diameter of a Mesh'   THEN qm."Value" END) AS "Max_Max3DDiameterMesh",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Minor Axis in 3D Length'         THEN qm."Value" END) AS "Max_MinorAxis3DLength",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Sphericity'                      THEN qm."Value" END) AS "Max_Sphericity",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Surface area of mesh'            THEN qm."Value" END) AS "Max_SurfaceAreaMesh",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Surface to Volume Ratio'         THEN qm."Value" END) AS "Max_SurfaceToVolumeRatio",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Volume from Voxel Summation'     THEN qm."Value" END) AS "Max_VolumeFromVoxelSummation",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Volume of mesh'                  THEN qm."Value" END) AS "Max_VolumeOfMesh"
FROM
    "IDC"."IDC_V17"."DICOM_ALL"               da
JOIN
    "IDC"."IDC_V17"."QUANTITATIVE_MEASUREMENTS" qm
        ON da."SOPInstanceUID" = qm."segmentationInstanceUID"
WHERE
    da."StudyDate" >= '2001-01-01'
    AND da."StudyDate" <  '2002-01-01'
GROUP BY
    da."PatientID",
    da."StudyInstanceUID",
    da."StudyDate",
    qm."findingSite":"CodeMeaning"::string
ORDER BY
    da."PatientID",
    da."StudyInstanceUID";