SELECT
    da."PatientID",
    da."StudyInstanceUID",
    da."StudyDate",
    (qm."findingSite":"CodeMeaning")::string       AS "FindingSite_CodeMeaning",

    /* maximum of each requested quantitative measurement */
    MAX(CASE WHEN (qm."Quantity":"CodeMeaning")::string = 'Elongation'
             THEN qm."Value" END)                  AS "Max_Elongation",

    MAX(CASE WHEN (qm."Quantity":"CodeMeaning")::string = 'Flatness'
             THEN qm."Value" END)                  AS "Max_Flatness",

    MAX(CASE WHEN (qm."Quantity":"CodeMeaning")::string = 'Least Axis in 3D Length'
             THEN qm."Value" END)                  AS "Max_Least_Axis_3D_Length",

    MAX(CASE WHEN (qm."Quantity":"CodeMeaning")::string = 'Major Axis in 3D Length'
             THEN qm."Value" END)                  AS "Max_Major_Axis_3D_Length",

    MAX(CASE WHEN (qm."Quantity":"CodeMeaning")::string = 'Maximum 3D Diameter of a Mesh'
             THEN qm."Value" END)                  AS "Max_Max_3D_Diameter_Mesh",

    MAX(CASE WHEN (qm."Quantity":"CodeMeaning")::string = 'Minor Axis in 3D Length'
             THEN qm."Value" END)                  AS "Max_Minor_Axis_3D_Length",

    MAX(CASE WHEN (qm."Quantity":"CodeMeaning")::string = 'Sphericity'
             THEN qm."Value" END)                  AS "Max_Sphericity",

    MAX(CASE WHEN (qm."Quantity":"CodeMeaning")::string = 'Surface area of mesh'
             THEN qm."Value" END)                  AS "Max_Surface_Area_Mesh",

    MAX(CASE WHEN (qm."Quantity":"CodeMeaning")::string = 'Surface to Volume Ratio'
             THEN qm."Value" END)                  AS "Max_Surface_to_Volume_Ratio",

    MAX(CASE WHEN (qm."Quantity":"CodeMeaning")::string = 'Volume from Voxel Summation'
             THEN qm."Value" END)                  AS "Max_Volume_from_Voxel_Summation",

    MAX(CASE WHEN (qm."Quantity":"CodeMeaning")::string = 'Volume of Mesh'
             THEN qm."Value" END)                  AS "Max_Volume_of_Mesh"

FROM  "IDC"."IDC_V17"."DICOM_ALL"               AS da
JOIN  "IDC"."IDC_V17"."QUANTITATIVE_MEASUREMENTS" AS qm
      ON qm."segmentationInstanceUID" = da."SOPInstanceUID"

WHERE EXTRACT(year FROM da."StudyDate") = 2001

GROUP BY
    da."PatientID",
    da."StudyInstanceUID",
    da."StudyDate",
    (qm."findingSite":"CodeMeaning")::string
;