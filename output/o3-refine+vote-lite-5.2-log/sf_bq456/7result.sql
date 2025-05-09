SELECT
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    qm."findingSite":"CodeMeaning"::string                        AS "FindingSite_CodeMeaning",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Elongation'
             THEN qm."Value" END)                                AS "max_Elongation",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Flatness'
             THEN qm."Value" END)                                AS "max_Flatness",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Least Axis in 3D Length'
             THEN qm."Value" END)                                AS "max_LeastAxis3DLength",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Major Axis in 3D Length'
             THEN qm."Value" END)                                AS "max_MajorAxis3DLength",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Maximum 3D Diameter of a Mesh'
             THEN qm."Value" END)                                AS "max_Max3DDiameterMesh",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Minor Axis in 3D Length'
             THEN qm."Value" END)                                AS "max_MinorAxis3DLength",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Sphericity'
             THEN qm."Value" END)                                AS "max_Sphericity",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Surface area of mesh'
             THEN qm."Value" END)                                AS "max_SurfaceAreaMesh",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Surface to volume ratio'
             THEN qm."Value" END)                                AS "max_SurfaceToVolumeRatio",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Volume from voxel summation'
             THEN qm."Value" END)                                AS "max_VolumeVoxelSummation",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Volume of mesh'
             THEN qm."Value" END)                                AS "max_VolumeMesh"
FROM
    IDC.IDC_V17.DICOM_ALL                    AS d
JOIN
    IDC.IDC_V17.QUANTITATIVE_MEASUREMENTS    AS qm
      ON qm."segmentationInstanceUID" = d."SOPInstanceUID"
WHERE
      d."StudyDate" BETWEEN '2001-01-01' AND '2001-12-31'
GROUP BY
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    qm."findingSite":"CodeMeaning"::string
;