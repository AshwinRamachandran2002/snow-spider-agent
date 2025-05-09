WITH filtered AS (
    SELECT
        da."PatientID",
        da."StudyInstanceUID",
        da."StudyDate",
        qm."findingSite":"CodeMeaning"::STRING  AS "FindingSite_CodeMeaning",
        UPPER(qm."Quantity":"CodeMeaning"::STRING) AS "Measurement",
        CAST(qm."Value" AS FLOAT)               AS "Value"
    FROM  IDC.IDC_V17."DICOM_ALL"               da
    JOIN  IDC.IDC_V17."QUANTITATIVE_MEASUREMENTS" qm
          ON qm."segmentationInstanceUID" = da."SOPInstanceUID"
    WHERE da."StudyDate" IS NOT NULL
      AND YEAR(da."StudyDate") = 2001
      AND UPPER(qm."Quantity":"CodeMeaning"::STRING) IN (
            'ELONGATION',
            'FLATNESS',
            'LEAST AXIS IN 3D LENGTH',
            'MAJOR AXIS IN 3D LENGTH',
            'MAXIMUM 3D DIAMETER OF A MESH',
            'MINOR AXIS IN 3D LENGTH',
            'SPHERICITY',
            'SURFACE AREA OF MESH',
            'SURFACE TO VOLUME RATIO',
            'VOLUME',
            'VOLUME OF MESH'
      )
)
SELECT
    "PatientID",
    "StudyInstanceUID",
    "StudyDate",
    "FindingSite_CodeMeaning",
    MAX(CASE WHEN "Measurement" = 'ELONGATION'                    THEN "Value" END) AS "Elongation_Max",
    MAX(CASE WHEN "Measurement" = 'FLATNESS'                      THEN "Value" END) AS "Flatness_Max",
    MAX(CASE WHEN "Measurement" = 'LEAST AXIS IN 3D LENGTH'       THEN "Value" END) AS "LeastAxis3D_Length_Max",
    MAX(CASE WHEN "Measurement" = 'MAJOR AXIS IN 3D LENGTH'       THEN "Value" END) AS "MajorAxis3D_Length_Max",
    MAX(CASE WHEN "Measurement" = 'MAXIMUM 3D DIAMETER OF A MESH' THEN "Value" END) AS "Max3DDiameterMesh_Max",
    MAX(CASE WHEN "Measurement" = 'MINOR AXIS IN 3D LENGTH'       THEN "Value" END) AS "MinorAxis3D_Length_Max",
    MAX(CASE WHEN "Measurement" = 'SPHERICITY'                    THEN "Value" END) AS "Sphericity_Max",
    MAX(CASE WHEN "Measurement" = 'SURFACE AREA OF MESH'          THEN "Value" END) AS "SurfaceAreaMesh_Max",
    MAX(CASE WHEN "Measurement" = 'SURFACE TO VOLUME RATIO'       THEN "Value" END) AS "SurfaceToVolumeRatio_Max",
    MAX(CASE WHEN "Measurement" = 'VOLUME'                        THEN "Value" END) AS "VolumeVoxelSummation_Max",
    MAX(CASE WHEN "Measurement" = 'VOLUME OF MESH'                THEN "Value" END) AS "VolumeMesh_Max"
FROM   filtered
GROUP BY
    "PatientID",
    "StudyInstanceUID",
    "StudyDate",
    "FindingSite_CodeMeaning";