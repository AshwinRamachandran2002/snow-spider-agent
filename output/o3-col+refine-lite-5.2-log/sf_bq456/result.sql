SELECT
    da."PatientID",
    da."StudyInstanceUID",
    da."StudyDate",
    /* CodeMeaning of the anatomic finding site */
    qm."findingSite":"CodeMeaning"::STRING         AS "FindingSite_CodeMeaning",

    /* maximum value of each requested quantitative measurement */
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Elongation'
             THEN qm."Value" END)                 AS "Elongation",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Flatness'
             THEN qm."Value" END)                 AS "Flatness",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Least Axis in 3D Length'
             THEN qm."Value" END)                 AS "LeastAxis_3D_Length",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Major Axis in 3D Length'
             THEN qm."Value" END)                 AS "MajorAxis_3D_Length",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Maximum 3D Diameter of a Mesh'
             THEN qm."Value" END)                 AS "Max_3D_Diameter_Mesh",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Minor Axis in 3D Length'
             THEN qm."Value" END)                 AS "MinorAxis_3D_Length",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Sphericity'
             THEN qm."Value" END)                 AS "Sphericity",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Surface area of mesh'
             THEN qm."Value" END)                 AS "SurfaceArea_Mesh",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Surface to volume ratio'
             THEN qm."Value" END)                 AS "SurfaceToVolume_Ratio",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Volume from Voxel Summation'
             THEN qm."Value" END)                 AS "Volume_From_Voxel_Summation",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::STRING = 'Volume of Mesh'
             THEN qm."Value" END)                 AS "Volume_Of_Mesh"

FROM
    IDC.IDC_V17."DICOM_ALL"                da
JOIN
    IDC.IDC_V17."QUANTITATIVE_MEASUREMENTS" qm
      ON qm."segmentationInstanceUID" = da."SOPInstanceUID"

WHERE
      /* Studies performed in calendar year 2001 */
      da."StudyDate" BETWEEN '2001-01-01' AND '2001-12-31'
  AND /* keep only the measurements of interest */
      qm."Quantity":"CodeMeaning"::STRING IN (
          'Elongation',
          'Flatness',
          'Least Axis in 3D Length',
          'Major Axis in 3D Length',
          'Maximum 3D Diameter of a Mesh',
          'Minor Axis in 3D Length',
          'Sphericity',
          'Surface area of mesh',
          'Surface to volume ratio',
          'Volume from Voxel Summation',
          'Volume of Mesh'
      )

GROUP BY
    da."PatientID",
    da."StudyInstanceUID",
    da."StudyDate",
    qm."findingSite":"CodeMeaning"::STRING

ORDER BY
    da."PatientID",
    da."StudyInstanceUID",
    da."StudyDate";