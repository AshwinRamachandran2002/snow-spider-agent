SELECT
    da."PatientID",
    da."StudyInstanceUID",
    da."StudyDate",
    /* CodeMeaning of the FindingSite */
    qm."findingSite":"CodeMeaning"::string                                   AS "FindingSite_CodeMeaning",

    /* maximum values of the requested quantitative measurements */
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Elongation'
             THEN qm."Value" END)                                            AS "Elongation",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Flatness'
             THEN qm."Value" END)                                            AS "Flatness",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Least Axis in 3D length'
             THEN qm."Value" END)                                            AS "Least_Axis_in_3D_Length",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Major Axis in 3D length'
             THEN qm."Value" END)                                            AS "Major_Axis_in_3D_Length",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Maximum 3D diameter of a mesh'
             THEN qm."Value" END)                                            AS "Maximum_3D_Diameter_of_Mesh",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Minor Axis in 3D length'
             THEN qm."Value" END)                                            AS "Minor_Axis_in_3D_Length",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Sphericity'
             THEN qm."Value" END)                                            AS "Sphericity",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Surface area of mesh'
             THEN qm."Value" END)                                            AS "Surface_Area_of_Mesh",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Surface to volume ratio'
             THEN qm."Value" END)                                            AS "Surface_to_Volume_Ratio",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Volume from voxel summation'
             THEN qm."Value" END)                                            AS "Volume_from_Voxel_Summation",
    MAX(CASE WHEN qm."Quantity":"CodeMeaning"::string = 'Volume of mesh'
             THEN qm."Value" END)                                            AS "Volume_of_Mesh"

FROM      "IDC"."IDC_V17"."DICOM_ALL"               AS da
JOIN      "IDC"."IDC_V17"."QUANTITATIVE_MEASUREMENTS" AS qm
          ON qm."segmentationInstanceUID" = da."SOPInstanceUID"

WHERE     da."StudyDate" IS NOT NULL
          AND EXTRACT(year FROM da."StudyDate") = 2001       -- restrict to studies performed in 2001

GROUP BY  da."PatientID",
          da."StudyInstanceUID",
          da."StudyDate",
          qm."findingSite":"CodeMeaning"::string

ORDER BY  da."PatientID",
          da."StudyInstanceUID",
          da."StudyDate";