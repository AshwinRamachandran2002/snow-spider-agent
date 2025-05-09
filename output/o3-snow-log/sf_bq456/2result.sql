SELECT 
    b."PatientID",
    b."StudyInstanceUID",
    b."StudyDate",
    /* Finding Site */
    qm."findingSite":"CodeMeaning"::string          AS "FindingSite_CodeMeaning",
    /* maximum of requested quantitative measurements */
    MAX( CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Elongation'                       THEN qm."Value" END ) AS "Max_Elongation",
    MAX( CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Flatness'                         THEN qm."Value" END ) AS "Max_Flatness",
    MAX( CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Least Axis in 3D Length'          THEN qm."Value" END ) AS "Max_LeastAxis3DLength",
    MAX( CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Major Axis in 3D Length'          THEN qm."Value" END ) AS "Max_MajorAxis3DLength",
    MAX( CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Maximum 3D Diameter of a Mesh'    THEN qm."Value" END ) AS "Max_Max3DDiameterMesh",
    MAX( CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Minor Axis in 3D Length'          THEN qm."Value" END ) AS "Max_MinorAxis3DLength",
    MAX( CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Sphericity'                       THEN qm."Value" END ) AS "Max_Sphericity",
    MAX( CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Surface area of mesh'             THEN qm."Value" END ) AS "Max_SurfaceAreaMesh",
    MAX( CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Surface to volume ratio'          THEN qm."Value" END ) AS "Max_SurfaceToVolumeRatio",
    MAX( CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Volume from voxel summation'      THEN qm."Value" END ) AS "Max_VolumeVoxelSummation",
    MAX( CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Volume of mesh'                   THEN qm."Value" END ) AS "Max_VolumeMesh"
FROM
    /* restrict to studies performed in 2001 */
    IDC.IDC_V17."DICOM_ALL"                       AS b
JOIN
    IDC.IDC_V17."QUANTITATIVE_MEASUREMENTS"       AS qm
      ON qm."segmentationInstanceUID" = b."SOPInstanceUID"
WHERE
      b."StudyDate" IS NOT NULL
  AND YEAR(b."StudyDate") = 2001
GROUP BY
    b."PatientID",
    b."StudyInstanceUID",
    b."StudyDate",
    qm."findingSite":"CodeMeaning"::string
ORDER BY
    b."PatientID",
    b."StudyInstanceUID",
    b."StudyDate";