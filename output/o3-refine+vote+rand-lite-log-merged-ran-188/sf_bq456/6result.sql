WITH qa AS (   -- keep the quantitative measurements we need
    SELECT
        "segmentationInstanceUID",
        "findingSite":"CodeMeaning"::STRING                 AS finding_site_cm,
        "Quantity":"CodeMeaning"::STRING                   AS quantity_cm,
        "Value"                                            AS measurement_value
    FROM IDC.IDC_V17."QUANTITATIVE_MEASUREMENTS"
    WHERE "Quantity":"CodeMeaning"::STRING IN
          ( 'Elongation',
            'Flatness',
            'Least Axis in 3D Length',
            'Major Axis in 3D Length',
            'Maximum 3D Diameter of a Mesh',
            'Minor Axis in 3D Length',
            'Sphericity',
            'Surface Area of Mesh',
            'Surface to Volume Ratio',
            'Volume from Voxel Summation',
            'Volume of Mesh')
),
da AS (   -- restrict to studies performed in 2001
    SELECT
        "PatientID",
        "StudyInstanceUID",
        "StudyDate",
        "SOPInstanceUID"
    FROM IDC.IDC_V17."DICOM_ALL"
    WHERE "StudyDate" BETWEEN '2001-01-01' AND '2001-12-31'
)

SELECT
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    q.finding_site_cm                                                       AS "FindingSite_CodeMeaning",

    MAX(CASE WHEN q.quantity_cm = 'Elongation'                    THEN q.measurement_value END) AS "Max_Elongation",
    MAX(CASE WHEN q.quantity_cm = 'Flatness'                      THEN q.measurement_value END) AS "Max_Flatness",
    MAX(CASE WHEN q.quantity_cm = 'Least Axis in 3D Length'       THEN q.measurement_value END) AS "Max_LeastAxis3DLength",
    MAX(CASE WHEN q.quantity_cm = 'Major Axis in 3D Length'       THEN q.measurement_value END) AS "Max_MajorAxis3DLength",
    MAX(CASE WHEN q.quantity_cm = 'Maximum 3D Diameter of a Mesh' THEN q.measurement_value END) AS "Max_Max3DDiameterMesh",
    MAX(CASE WHEN q.quantity_cm = 'Minor Axis in 3D Length'       THEN q.measurement_value END) AS "Max_MinorAxis3DLength",
    MAX(CASE WHEN q.quantity_cm = 'Sphericity'                    THEN q.measurement_value END) AS "Max_Sphericity",
    MAX(CASE WHEN q.quantity_cm = 'Surface Area of Mesh'          THEN q.measurement_value END) AS "Max_SurfaceAreaMesh",
    MAX(CASE WHEN q.quantity_cm = 'Surface to Volume Ratio'       THEN q.measurement_value END) AS "Max_SurfaceToVolumeRatio",
    MAX(CASE WHEN q.quantity_cm = 'Volume from Voxel Summation'   THEN q.measurement_value END) AS "Max_VolumeFromVoxelSummation",
    MAX(CASE WHEN q.quantity_cm = 'Volume of Mesh'                THEN q.measurement_value END) AS "Max_VolumeOfMesh"

FROM da d
JOIN qa q
      ON q."segmentationInstanceUID" = d."SOPInstanceUID"
GROUP BY
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    q.finding_site_cm;