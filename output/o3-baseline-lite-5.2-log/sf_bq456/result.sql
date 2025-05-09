WITH q_filtered AS (
    SELECT
        q."segmentationInstanceUID",
        (q."Quantity":"CodeMeaning"::string)          AS quantity_cm,
        q."Value"::FLOAT                              AS quantity_value,
        (q."findingSite":"CodeMeaning"::string)       AS finding_site_cm
    FROM IDC.IDC_V17."QUANTITATIVE_MEASUREMENTS" q
    WHERE (q."Quantity":"CodeMeaning"::string) IN (
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
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    qf.finding_site_cm                                                    AS "FindingSite_CodeMeaning",
    MAX(CASE WHEN qf.quantity_cm = 'Elongation'                    THEN qf.quantity_value END) AS "max_Elongation",
    MAX(CASE WHEN qf.quantity_cm = 'Flatness'                      THEN qf.quantity_value END) AS "max_Flatness",
    MAX(CASE WHEN qf.quantity_cm = 'Least Axis in 3D Length'       THEN qf.quantity_value END) AS "max_LeastAxis3DLength",
    MAX(CASE WHEN qf.quantity_cm = 'Major Axis in 3D Length'       THEN qf.quantity_value END) AS "max_MajorAxis3DLength",
    MAX(CASE WHEN qf.quantity_cm = 'Maximum 3D Diameter of a Mesh' THEN qf.quantity_value END) AS "max_Max3DDiameterMesh",
    MAX(CASE WHEN qf.quantity_cm = 'Minor Axis in 3D Length'       THEN qf.quantity_value END) AS "max_MinorAxis3DLength",
    MAX(CASE WHEN qf.quantity_cm = 'Sphericity'                    THEN qf.quantity_value END) AS "max_Sphericity",
    MAX(CASE WHEN qf.quantity_cm = 'Surface area of mesh'          THEN qf.quantity_value END) AS "max_SurfaceAreaMesh",
    MAX(CASE WHEN qf.quantity_cm = 'Surface to Volume Ratio'       THEN qf.quantity_value END) AS "max_SurfaceToVolumeRatio",
    MAX(CASE WHEN qf.quantity_cm = 'Volume from Voxel Summation'   THEN qf.quantity_value END) AS "max_VolumeVoxelSummation",
    MAX(CASE WHEN qf.quantity_cm = 'Volume of Mesh'                THEN qf.quantity_value END) AS "max_VolumeMesh"
FROM IDC.IDC_V17."DICOM_ALL" d
JOIN q_filtered qf
  ON qf."segmentationInstanceUID" = d."SOPInstanceUID"
WHERE d."StudyDate" BETWEEN '2001-01-01' AND '2001-12-31'
GROUP BY
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    qf.finding_site_cm;