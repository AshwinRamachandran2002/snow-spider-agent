SELECT
    da."PatientID",
    da."StudyInstanceUID",
    da."StudyDate",
    qm."findingSite":"CodeMeaning"::string                          AS "FindingSite_CodeMeaning",

    /* maximum of requested quantitative measurements */
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::string) = 'elongation'                        THEN qm."Value" END) AS "max_Elongation",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::string) = 'flatness'                          THEN qm."Value" END) AS "max_Flatness",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::string) = 'least axis in 3d length'           THEN qm."Value" END) AS "max_Least_Axis_3D_Length",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::string) = 'major axis in 3d length'           THEN qm."Value" END) AS "max_Major_Axis_3D_Length",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::string) = 'maximum 3d diameter of a mesh'     THEN qm."Value" END) AS "max_Maximum_3D_Diameter_Mesh",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::string) = 'minor axis in 3d length'           THEN qm."Value" END) AS "max_Minor_Axis_3D_Length",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::string) = 'sphericity'                        THEN qm."Value" END) AS "max_Sphericity",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::string) = 'surface area of mesh'              THEN qm."Value" END) AS "max_Surface_Area_Mesh",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::string) = 'surface to volume ratio'           THEN qm."Value" END) AS "max_Surface_to_Volume_Ratio",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::string) = 'volume from voxel summation'       THEN qm."Value" END) AS "max_Volume_Voxel_Summation",
    MAX(CASE WHEN LOWER(qm."Quantity":"CodeMeaning"::string) = 'volume of mesh'                    THEN qm."Value" END) AS "max_Volume_of_Mesh"

FROM  IDC.IDC_V17.DICOM_ALL                AS da
JOIN  IDC.IDC_V17.QUANTITATIVE_MEASUREMENTS AS qm
      ON  da."SOPInstanceUID" = qm."segmentationInstanceUID"

WHERE da."StudyDate" BETWEEN '2001-01-01' AND '2001-12-31'

GROUP BY
      da."PatientID",
      da."StudyInstanceUID",
      da."StudyDate",
      qm."findingSite":"CodeMeaning"::string;