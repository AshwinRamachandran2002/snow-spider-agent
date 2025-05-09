WITH qm AS (
    SELECT
        q."segmentationInstanceUID",
        q."Quantity":CodeMeaning::STRING      AS quantity_code,
        q."Value"                             AS measurement_value,
        q."findingSite":CodeMeaning::STRING   AS finding_site_code
    FROM IDC.IDC_V17."QUANTITATIVE_MEASUREMENTS" q
)

SELECT
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    qm.finding_site_code                                                     AS "FindingSite_CodeMeaning",

    MAX(CASE WHEN qm.quantity_code = 'Elongation'                    THEN qm.measurement_value END) AS "Elongation_max",
    MAX(CASE WHEN qm.quantity_code = 'Flatness'                      THEN qm.measurement_value END) AS "Flatness_max",
    MAX(CASE WHEN qm.quantity_code = 'Least Axis in 3D Length'       THEN qm.measurement_value END) AS "LeastAxis3DLength_max",
    MAX(CASE WHEN qm.quantity_code = 'Major Axis in 3D Length'       THEN qm.measurement_value END) AS "MajorAxis3DLength_max",
    MAX(CASE WHEN qm.quantity_code = 'Maximum 3D Diameter of a Mesh' THEN qm.measurement_value END) AS "Max3DDiameterMesh_max",
    MAX(CASE WHEN qm.quantity_code = 'Minor Axis in 3D Length'       THEN qm.measurement_value END) AS "MinorAxis3DLength_max",
    MAX(CASE WHEN qm.quantity_code = 'Sphericity'                    THEN qm.measurement_value END) AS "Sphericity_max",
    MAX(CASE WHEN qm.quantity_code = 'Surface area of mesh'          THEN qm.measurement_value END) AS "SurfaceAreaMesh_max",
    MAX(CASE WHEN qm.quantity_code = 'Surface to volume ratio'       THEN qm.measurement_value END) AS "SurfaceToVolumeRatio_max",
    MAX(CASE WHEN qm.quantity_code = 'Volume from voxel summation'   THEN qm.measurement_value END) AS "VolumeFromVoxelSummation_max",
    MAX(CASE WHEN qm.quantity_code = 'Volume of mesh'                THEN qm.measurement_value END) AS "VolumeOfMesh_max"

FROM IDC.IDC_V17."DICOM_ALL" d
JOIN qm
  ON qm."segmentationInstanceUID" = d."SOPInstanceUID"

WHERE d."StudyDate" BETWEEN '2001-01-01' AND '2001-12-31'

GROUP BY
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    qm.finding_site_code

ORDER BY
    d."PatientID",
    d."StudyInstanceUID",
    qm.finding_site_code;