WITH quant_filtered AS (
    SELECT
        q."segmentationInstanceUID",
        q."Value",
        q."Quantity":"CodeMeaning"::string              AS quantity_name,
        q."findingSite":"CodeMeaning"::string           AS finding_site_code_meaning
    FROM IDC.IDC_V17."QUANTITATIVE_MEASUREMENTS" q
    WHERE q."Quantity":"CodeMeaning"::string IN (
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
            'Volume of mesh'
        )
),
study_2001 AS (
    SELECT
        d."PatientID",
        d."StudyInstanceUID",
        d."StudyDate",
        d."SOPInstanceUID"
    FROM IDC.IDC_V17."DICOM_ALL" d
    WHERE d."StudyDate" BETWEEN '2001-01-01' AND '2001-12-31'
)

SELECT
    s."PatientID",
    s."StudyInstanceUID",
    s."StudyDate",
    qf.finding_site_code_meaning                       AS "FindingSite_CodeMeaning",
    MAX(CASE WHEN qf.quantity_name = 'Elongation'                       THEN qf."Value" END) AS "Elongation_max",
    MAX(CASE WHEN qf.quantity_name = 'Flatness'                         THEN qf."Value" END) AS "Flatness_max",
    MAX(CASE WHEN qf.quantity_name = 'Least Axis in 3D Length'          THEN qf."Value" END) AS "LeastAxis3DLength_max",
    MAX(CASE WHEN qf.quantity_name = 'Major Axis in 3D Length'          THEN qf."Value" END) AS "MajorAxis3DLength_max",
    MAX(CASE WHEN qf.quantity_name = 'Maximum 3D Diameter of a Mesh'    THEN qf."Value" END) AS "Max3DDiameterMesh_max",
    MAX(CASE WHEN qf.quantity_name = 'Minor Axis in 3D Length'          THEN qf."Value" END) AS "MinorAxis3DLength_max",
    MAX(CASE WHEN qf.quantity_name = 'Sphericity'                       THEN qf."Value" END) AS "Sphericity_max",
    MAX(CASE WHEN qf.quantity_name = 'Surface area of mesh'             THEN qf."Value" END) AS "SurfaceAreaMesh_max",
    MAX(CASE WHEN qf.quantity_name = 'Surface to Volume Ratio'          THEN qf."Value" END) AS "SurfaceToVolumeRatio_max",
    MAX(CASE WHEN qf.quantity_name = 'Volume from Voxel Summation'      THEN qf."Value" END) AS "VolumeVoxelSummation_max",
    MAX(CASE WHEN qf.quantity_name = 'Volume of mesh'                   THEN qf."Value" END) AS "VolumeMesh_max"
FROM study_2001 s
JOIN quant_filtered qf
      ON qf."segmentationInstanceUID" = s."SOPInstanceUID"
GROUP BY
    s."PatientID",
    s."StudyInstanceUID",
    s."StudyDate",
    qf.finding_site_code_meaning
ORDER BY
    s."PatientID",
    s."StudyInstanceUID",
    s."StudyDate";