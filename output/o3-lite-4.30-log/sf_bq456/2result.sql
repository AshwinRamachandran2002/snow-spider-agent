WITH measurement_data AS (
    SELECT
        d."PatientID",
        d."StudyInstanceUID",
        d."StudyDate",
        q."findingSite":"CodeMeaning"::STRING  AS "FindingSiteCodeMeaning",
        q."Quantity":"CodeMeaning"::STRING     AS "QuantityCodeMeaning",
        q."Value"                              AS "Value"
    FROM  IDC.IDC_V17.QUANTITATIVE_MEASUREMENTS q
    JOIN  IDC.IDC_V17.DICOM_ALL                d
          ON q."segmentationInstanceUID" = d."SOPInstanceUID"
    WHERE d."StudyDate" BETWEEN '2001-01-01' AND '2001-12-31'
      AND q."Quantity":"CodeMeaning"::STRING IN (
            'Elongation',
            'Flatness',
            'Least Axis in 3D Length',
            'Major Axis in 3D Length',
            'Maximum 3D Diameter of a Mesh',
            'Minor Axis in 3D Length',
            'Sphericity',
            'Surface Area of Mesh',
            'Surface to Volume Ratio',
            'Volume from Voxel Summation',
            'Volume of Mesh'
          )
)
SELECT
    "PatientID",
    "StudyInstanceUID",
    "StudyDate",
    "FindingSiteCodeMeaning",
    ROUND(MAX(CASE WHEN "QuantityCodeMeaning" = 'Elongation'                     THEN "Value" END), 4) AS "Elongation_Max",
    ROUND(MAX(CASE WHEN "QuantityCodeMeaning" = 'Flatness'                      THEN "Value" END), 4) AS "Flatness_Max",
    ROUND(MAX(CASE WHEN "QuantityCodeMeaning" = 'Least Axis in 3D Length'       THEN "Value" END), 4) AS "LeastAxis3DLength_Max",
    ROUND(MAX(CASE WHEN "QuantityCodeMeaning" = 'Major Axis in 3D Length'       THEN "Value" END), 4) AS "MajorAxis3DLength_Max",
    ROUND(MAX(CASE WHEN "QuantityCodeMeaning" = 'Maximum 3D Diameter of a Mesh' THEN "Value" END), 4) AS "Maximum3DDiameterMesh_Max",
    ROUND(MAX(CASE WHEN "QuantityCodeMeaning" = 'Minor Axis in 3D Length'       THEN "Value" END), 4) AS "MinorAxis3DLength_Max",
    ROUND(MAX(CASE WHEN "QuantityCodeMeaning" = 'Sphericity'                    THEN "Value" END), 4) AS "Sphericity_Max",
    ROUND(MAX(CASE WHEN "QuantityCodeMeaning" = 'Surface Area of Mesh'          THEN "Value" END), 4) AS "SurfaceAreaMesh_Max",
    ROUND(MAX(CASE WHEN "QuantityCodeMeaning" = 'Surface to Volume Ratio'       THEN "Value" END), 4) AS "SurfaceToVolumeRatio_Max",
    ROUND(MAX(CASE WHEN "QuantityCodeMeaning" = 'Volume from Voxel Summation'   THEN "Value" END), 4) AS "VolumeFromVoxelSummation_Max",
    ROUND(MAX(CASE WHEN "QuantityCodeMeaning" = 'Volume of Mesh'                THEN "Value" END), 4) AS "VolumeOfMesh_Max"
FROM   measurement_data
GROUP BY
    "PatientID",
    "StudyInstanceUID",
    "StudyDate",
    "FindingSiteCodeMeaning";