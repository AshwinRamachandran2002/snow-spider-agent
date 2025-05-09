SELECT
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    LOWER(q."findingSite":"CodeMeaning"::string)                       AS "FindingSite_CodeMeaning",
    /* maximum of each requested quantitative measurement */
    MAX(CASE WHEN LOWER(q."Quantity":"CodeMeaning"::string) = 'elongation'
             THEN q."Value" END)                                      AS "Max_Elongation",
    MAX(CASE WHEN LOWER(q."Quantity":"CodeMeaning"::string) = 'flatness'
             THEN q."Value" END)                                      AS "Max_Flatness",
    MAX(CASE WHEN LOWER(q."Quantity":"CodeMeaning"::string) = 'least axis in 3d length'
             THEN q."Value" END)                                      AS "Max_LeastAxis3DLength",
    MAX(CASE WHEN LOWER(q."Quantity":"CodeMeaning"::string) = 'major axis in 3d length'
             THEN q."Value" END)                                      AS "Max_MajorAxis3DLength",
    MAX(CASE WHEN LOWER(q."Quantity":"CodeMeaning"::string) = 'maximum 3d diameter of a mesh'
             THEN q."Value" END)                                      AS "Max_Max3DDiameterMesh",
    MAX(CASE WHEN LOWER(q."Quantity":"CodeMeaning"::string) = 'minor axis in 3d length'
             THEN q."Value" END)                                      AS "Max_MinorAxis3DLength",
    MAX(CASE WHEN LOWER(q."Quantity":"CodeMeaning"::string) = 'sphericity'
             THEN q."Value" END)                                      AS "Max_Sphericity",
    MAX(CASE WHEN LOWER(q."Quantity":"CodeMeaning"::string) = 'surface area of mesh'
             THEN q."Value" END)                                      AS "Max_SurfaceAreaMesh",
    MAX(CASE WHEN LOWER(q."Quantity":"CodeMeaning"::string) = 'surface to volume ratio'
             THEN q."Value" END)                                      AS "Max_SurfaceToVolumeRatio",
    MAX(CASE WHEN LOWER(q."Quantity":"CodeMeaning"::string) = 'volume from voxel summation'
             THEN q."Value" END)                                      AS "Max_VolumeVoxelSummation",
    MAX(CASE WHEN LOWER(q."Quantity":"CodeMeaning"::string) = 'volume of mesh'
             THEN q."Value" END)                                      AS "Max_VolumeMesh"
FROM
    IDC.IDC_V17.DICOM_ALL               d
JOIN
    IDC.IDC_V17.QUANTITATIVE_MEASUREMENTS q
      ON q."segmentationInstanceUID" = d."SOPInstanceUID"
WHERE
    YEAR(d."StudyDate") = 2001
GROUP BY
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    LOWER(q."findingSite":"CodeMeaning"::string)
;