SELECT
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    q."findingSite":CodeMeaning::STRING AS "FindingSite_CodeMeaning",
    MAX(CASE WHEN q."Quantity":CodeMeaning::STRING = 'Elongation' THEN q."Value" END) AS "Max_Elongation",
    MAX(CASE WHEN q."Quantity":CodeMeaning::STRING = 'Flatness' THEN q."Value" END) AS "Max_Flatness",
    MAX(CASE WHEN q."Quantity":CodeMeaning::STRING = 'Least Axis in 3D Length' THEN q."Value" END) AS "Max_Least_Axis_in_3D_Length",
    MAX(CASE WHEN q."Quantity":CodeMeaning::STRING = 'Major Axis in 3D Length' THEN q."Value" END) AS "Max_Major_Axis_in_3D_Length",
    MAX(CASE WHEN q."Quantity":CodeMeaning::STRING = 'Maximum 3D Diameter of a Mesh' THEN q."Value" END) AS "Max_Maximum_3D_Diameter_of_a_Mesh",
    MAX(CASE WHEN q."Quantity":CodeMeaning::STRING = 'Minor Axis in 3D Length' THEN q."Value" END) AS "Max_Minor_Axis_in_3D_Length",
    MAX(CASE WHEN q."Quantity":CodeMeaning::STRING = 'Sphericity' THEN q."Value" END) AS "Max_Sphericity",
    MAX(CASE WHEN q."Quantity":CodeMeaning::STRING = 'Surface Area of Mesh' THEN q."Value" END) AS "Max_Surface_Area_of_Mesh",
    MAX(CASE WHEN q."Quantity":CodeMeaning::STRING = 'Surface to Volume Ratio' THEN q."Value" END) AS "Max_Surface_to_Volume_Ratio",
    MAX(CASE WHEN q."Quantity":CodeMeaning::STRING = 'Volume from Voxel Summation' THEN q."Value" END) AS "Max_Volume_from_Voxel_Summation",
    MAX(CASE WHEN q."Quantity":CodeMeaning::STRING = 'Volume of Mesh' THEN q."Value" END) AS "Max_Volume_of_Mesh"
FROM
    IDC.IDC_V17.DICOM_ALL d
JOIN
    IDC.IDC_V17.QUANTITATIVE_MEASUREMENTS q
    ON d."SOPInstanceUID" = q."segmentationInstanceUID"
WHERE
    EXTRACT(YEAR FROM d."StudyDate") = 2001
    AND q."Quantity":CodeMeaning::STRING IN (
        'Elongation',
        'Flatness',
        'Least Axis in 3D Length',
        'Major Axis in 3D Length',
        'Maximum 3D Diameter of a Mesh',
        'Minor Axis in 3D Length',
        'Sphericity',
        'Surface Area of Mesh',
        'Surface to Volume Ratio',
        'Volume from Voxel Summation',
        'Volume of Mesh'
    )
GROUP BY
    d."PatientID",
    d."StudyInstanceUID",
    d."StudyDate",
    q."findingSite":CodeMeaning::STRING
ORDER BY
    d."PatientID",
    q."findingSite":CodeMeaning::STRING;