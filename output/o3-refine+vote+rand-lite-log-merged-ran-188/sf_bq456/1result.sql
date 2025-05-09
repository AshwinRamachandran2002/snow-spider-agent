WITH qm_join AS (
    SELECT
        d."PatientID",
        d."StudyInstanceUID",
        d."StudyDate",
        /* CodeMeaning for the Finding Site */
        qm."findingSite":"CodeMeaning"::STRING                AS "FindingSite_CodeMeaning",
        /* CodeMeaning that identifies the kind of measurement */
        UPPER(qm."Quantity":"CodeMeaning"::STRING)            AS quantity_name,
        qm."Value"::FLOAT                                     AS quantity_value
    FROM IDC.IDC_V17."DICOM_ALL"                d
    JOIN IDC.IDC_V17."QUANTITATIVE_MEASUREMENTS" qm
         ON qm."segmentationInstanceUID" = d."SOPInstanceUID"
    /* keep only studies performed in calendar year 2001 */
    WHERE d."StudyDate" BETWEEN '2001-01-01' AND '2001-12-31'
)

SELECT
    "PatientID",
    "StudyInstanceUID",
    "StudyDate",
    "FindingSite_CodeMeaning",
    /* maximum of each requested quantitative measurement */
    MAX(CASE WHEN quantity_name = 'ELONGATION'                     THEN quantity_value END) AS "Max_Elongation",
    MAX(CASE WHEN quantity_name = 'FLATNESS'                       THEN quantity_value END) AS "Max_Flatness",
    MAX(CASE WHEN quantity_name = 'LEAST AXIS IN 3D LENGTH'        THEN quantity_value END) AS "Max_LeastAxis3DLength",
    MAX(CASE WHEN quantity_name = 'MAJOR AXIS IN 3D LENGTH'        THEN quantity_value END) AS "Max_MajorAxis3DLength",
    MAX(CASE WHEN quantity_name = 'MAXIMUM 3D DIAMETER OF A MESH'  THEN quantity_value END) AS "Max_Maximum3DDiameterMesh",
    MAX(CASE WHEN quantity_name = 'MINOR AXIS IN 3D LENGTH'        THEN quantity_value END) AS "Max_MinorAxis3DLength",
    MAX(CASE WHEN quantity_name = 'SPHERICITY'                     THEN quantity_value END) AS "Max_Sphericity",
    MAX(CASE WHEN quantity_name = 'SURFACE AREA OF MESH'           THEN quantity_value END) AS "Max_SurfaceAreaMesh",
    MAX(CASE WHEN quantity_name = 'SURFACE TO VOLUME RATIO'        THEN quantity_value END) AS "Max_SurfaceToVolumeRatio",
    MAX(CASE WHEN quantity_name = 'VOLUME FROM VOXEL SUMMATION'    THEN quantity_value END) AS "Max_VolumeVoxelSummation",
    MAX(CASE WHEN quantity_name = 'VOLUME OF MESH'                 THEN quantity_value END) AS "Max_VolumeMesh"
FROM qm_join
GROUP BY
    "PatientID",
    "StudyInstanceUID",
    "StudyDate",
    "FindingSite_CodeMeaning"
ORDER BY
    "PatientID",
    "StudyInstanceUID";