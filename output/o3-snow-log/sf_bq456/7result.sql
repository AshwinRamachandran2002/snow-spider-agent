SELECT
    dcm."PatientID",
    dcm."StudyInstanceUID",
    dcm."StudyDate",
    q."findingSite":"CodeMeaning"::string                     AS "FindingSite_CodeMeaning",

    /* ---- maximum of each requested measurement ---- */
    MAX( CASE WHEN q."Quantity":"CodeMeaning"::string = 'Elongation'
              THEN q."Value" END )                           AS "Max_Elongation",

    MAX( CASE WHEN q."Quantity":"CodeMeaning"::string = 'Flatness'
              THEN q."Value" END )                           AS "Max_Flatness",

    MAX( CASE WHEN q."Quantity":"CodeMeaning"::string = 'Least Axis in 3D Length'
              THEN q."Value" END )                           AS "Max_LeastAxis3DLength",

    MAX( CASE WHEN q."Quantity":"CodeMeaning"::string = 'Major Axis in 3D Length'
              THEN q."Value" END )                           AS "Max_MajorAxis3DLength",

    MAX( CASE WHEN q."Quantity":"CodeMeaning"::string = 'Maximum 3D Diameter of a Mesh'
              THEN q."Value" END )                           AS "Max_Max3DDiameterMesh",

    MAX( CASE WHEN q."Quantity":"CodeMeaning"::string = 'Minor Axis in 3D Length'
              THEN q."Value" END )                           AS "Max_MinorAxis3DLength",

    MAX( CASE WHEN q."Quantity":"CodeMeaning"::string = 'Sphericity'
              THEN q."Value" END )                           AS "Max_Sphericity",

    MAX( CASE WHEN q."Quantity":"CodeMeaning"::string = 'Surface area of mesh'
              THEN q."Value" END )                           AS "Max_SurfaceAreaMesh",

    MAX( CASE WHEN q."Quantity":"CodeMeaning"::string = 'Surface to Volume Ratio'
              THEN q."Value" END )                           AS "Max_SurfaceToVolumeRatio",

    MAX( CASE WHEN q."Quantity":"CodeMeaning"::string = 'Volume from Voxel Summation'
              THEN q."Value" END )                           AS "Max_VolumeVoxelSummation",

    MAX( CASE WHEN q."Quantity":"CodeMeaning"::string = 'Volume of mesh'
              THEN q."Value" END )                           AS "Max_VolumeMesh"

FROM  "IDC"."IDC_V17"."DICOM_ALL"               AS dcm
JOIN  "IDC"."IDC_V17"."QUANTITATIVE_MEASUREMENTS" AS q
      ON q."segmentationInstanceUID" = dcm."SOPInstanceUID"

WHERE EXTRACT(year FROM dcm."StudyDate") = 2001

GROUP BY
    dcm."PatientID",
    dcm."StudyInstanceUID",
    dcm."StudyDate",
    q."findingSite":"CodeMeaning"::string

ORDER BY
    dcm."PatientID",
    dcm."StudyInstanceUID";