WITH measurements AS (
    /*------------------------------------------------------------------
      Keep only the measurements of interest and extract the useful keys
    ------------------------------------------------------------------*/
    SELECT
        "segmentationInstanceUID",
        UPPER("Quantity":"CodeMeaning"::STRING)        AS measurement_name,
        "Value"                                       AS measurement_value,
        "findingSite":"CodeMeaning"::STRING           AS finding_site_codemeaning
    FROM IDC.IDC_V17.QUANTITATIVE_MEASUREMENTS
    WHERE UPPER("Quantity":"CodeMeaning"::STRING) IN (
          'ELONGATION',
          'FLATNESS',
          'LEAST AXIS IN 3D LENGTH',
          'MAJOR AXIS IN 3D LENGTH',
          'MAXIMUM 3D DIAMETER OF A MESH',
          'MINOR AXIS IN 3D LENGTH',
          'SPHERICITY',
          'SURFACE AREA OF MESH',
          'SURFACE TO VOLUME RATIO',
          'VOLUME FROM VOXEL SUMMATION',
          'VOLUME OF MESH'
    )
)

SELECT
    da."PatientID",
    da."StudyInstanceUID",
    da."StudyDate",
    m.finding_site_codemeaning                                         AS "FindingSite_CodeMeaning",

    /*------------------------------------------------------------------
      Maximum value of each requested measurement
    ------------------------------------------------------------------*/
    MAX(CASE WHEN m.measurement_name = 'ELONGATION'                     THEN m.measurement_value END) AS "Elongation",
    MAX(CASE WHEN m.measurement_name = 'FLATNESS'                       THEN m.measurement_value END) AS "Flatness",
    MAX(CASE WHEN m.measurement_name = 'LEAST AXIS IN 3D LENGTH'        THEN m.measurement_value END) AS "Least_Axis_in_3D_Length",
    MAX(CASE WHEN m.measurement_name = 'MAJOR AXIS IN 3D LENGTH'        THEN m.measurement_value END) AS "Major_Axis_in_3D_Length",
    MAX(CASE WHEN m.measurement_name = 'MAXIMUM 3D DIAMETER OF A MESH'  THEN m.measurement_value END) AS "Maximum_3D_Diameter_of_a_Mesh",
    MAX(CASE WHEN m.measurement_name = 'MINOR AXIS IN 3D LENGTH'        THEN m.measurement_value END) AS "Minor_Axis_in_3D_Length",
    MAX(CASE WHEN m.measurement_name = 'SPHERICITY'                     THEN m.measurement_value END) AS "Sphericity",
    MAX(CASE WHEN m.measurement_name = 'SURFACE AREA OF MESH'           THEN m.measurement_value END) AS "Surface_Area_of_Mesh",
    MAX(CASE WHEN m.measurement_name = 'SURFACE TO VOLUME RATIO'        THEN m.measurement_value END) AS "Surface_to_Volume_Ratio",
    MAX(CASE WHEN m.measurement_name = 'VOLUME FROM VOXEL SUMMATION'    THEN m.measurement_value END) AS "Volume_from_Voxel_Summation",
    MAX(CASE WHEN m.measurement_name = 'VOLUME OF MESH'                 THEN m.measurement_value END) AS "Volume_of_Mesh"

FROM IDC.IDC_V17.DICOM_ALL                da
JOIN measurements                         m
     ON da."SOPInstanceUID" = m."segmentationInstanceUID"

WHERE EXTRACT(YEAR FROM da."StudyDate") = 2001

GROUP BY
    da."PatientID",
    da."StudyInstanceUID",
    da."StudyDate",
    m.finding_site_codemeaning;