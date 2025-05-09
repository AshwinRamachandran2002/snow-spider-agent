WITH measurement_values AS (
    SELECT
        da."PatientID",
        da."StudyInstanceUID",
        da."StudyDate",
        /* CodeMeaning of the FindingSite */
        qm."findingSite":"CodeMeaning"::string                 AS "FindingSite_CodeMeaning",
        /* CodeMeaning that identifies which measurement this row represents */
        qm."Quantity":"CodeMeaning"::string                    AS "Quantity_CodeMeaning",
        /* numeric value of the measurement */
        CAST(qm."Value" AS FLOAT)                              AS "MeasurementValue"
    FROM "IDC"."IDC_V17"."DICOM_ALL"              da
    JOIN "IDC"."IDC_V17"."QUANTITATIVE_MEASUREMENTS" qm
         ON qm."segmentationInstanceUID" = da."SOPInstanceUID"
    /* keep only studies performed in calendar year 2001 */
    WHERE da."StudyDate" BETWEEN '2001-01-01' AND '2001-12-31'
      /* keep only the measurements we are interested in */
      AND qm."Quantity":"CodeMeaning"::string IN (
            'Elongation',
            'Flatness',
            'Least Axis in 3D Length',
            'Major Axis in 3D Length',
            'Maximum 3D Diameter of a Mesh',
            'Minor Axis in 3D Length',
            'Sphericity',
            'Surface area of mesh',
            'Surface to Volume Ratio',
            'Volume from Voxel Summation',
            'Volume of Mesh'
      )
)

SELECT
    "PatientID",
    "StudyInstanceUID",
    "StudyDate",
    "FindingSite_CodeMeaning",
    /* max‑value for each requested measurement */
    MAX(CASE WHEN "Quantity_CodeMeaning" = 'Elongation'                     THEN "MeasurementValue" END) AS "Max_Elongation",
    MAX(CASE WHEN "Quantity_CodeMeaning" = 'Flatness'                       THEN "MeasurementValue" END) AS "Max_Flatness",
    MAX(CASE WHEN "Quantity_CodeMeaning" = 'Least Axis in 3D Length'        THEN "MeasurementValue" END) AS "Max_LeastAxis3DLength",
    MAX(CASE WHEN "Quantity_CodeMeaning" = 'Major Axis in 3D Length'        THEN "MeasurementValue" END) AS "Max_MajorAxis3DLength",
    MAX(CASE WHEN "Quantity_CodeMeaning" = 'Maximum 3D Diameter of a Mesh'  THEN "MeasurementValue" END) AS "Max_Max3DDiameterMesh",
    MAX(CASE WHEN "Quantity_CodeMeaning" = 'Minor Axis in 3D Length'        THEN "MeasurementValue" END) AS "Max_MinorAxis3DLength",
    MAX(CASE WHEN "Quantity_CodeMeaning" = 'Sphericity'                     THEN "MeasurementValue" END) AS "Max_Sphericity",
    MAX(CASE WHEN "Quantity_CodeMeaning" = 'Surface area of mesh'           THEN "MeasurementValue" END) AS "Max_SurfaceAreaMesh",
    MAX(CASE WHEN "Quantity_CodeMeaning" = 'Surface to Volume Ratio'        THEN "MeasurementValue" END) AS "Max_SurfaceToVolumeRatio",
    MAX(CASE WHEN "Quantity_CodeMeaning" = 'Volume from Voxel Summation'    THEN "MeasurementValue" END) AS "Max_VolumeVoxelSummation",
    MAX(CASE WHEN "Quantity_CodeMeaning" = 'Volume of Mesh'                 THEN "MeasurementValue" END) AS "Max_VolumeMesh"
FROM measurement_values
GROUP BY
    "PatientID",
    "StudyInstanceUID",
    "StudyDate",
    "FindingSite_CodeMeaning";