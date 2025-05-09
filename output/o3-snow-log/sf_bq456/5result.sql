SELECT
    D."PatientID",
    D."StudyInstanceUID",
    D."StudyDate",
    QUANT."findingSite":"CodeMeaning"::string AS "FindingSite_CodeMeaning",
    
    /* maximum of each requested quantitative measurement */
    MAX(CASE WHEN QUANT."Quantity":"CodeMeaning"::string = 'Elongation'
             THEN QUANT."Value" END)                       AS "Max_Elongation",
             
    MAX(CASE WHEN QUANT."Quantity":"CodeMeaning"::string = 'Flatness'
             THEN QUANT."Value" END)                       AS "Max_Flatness",
             
    MAX(CASE WHEN QUANT."Quantity":"CodeMeaning"::string = 'Least Axis in 3D Length'
             THEN QUANT."Value" END)                       AS "Max_LeastAxis3DLength",
             
    MAX(CASE WHEN QUANT."Quantity":"CodeMeaning"::string = 'Major Axis in 3D Length'
             THEN QUANT."Value" END)                       AS "Max_MajorAxis3DLength",
             
    MAX(CASE WHEN QUANT."Quantity":"CodeMeaning"::string = 'Maximum 3D Diameter of a Mesh'
             THEN QUANT."Value" END)                       AS "Max_Max3DDiameterMesh",
             
    MAX(CASE WHEN QUANT."Quantity":"CodeMeaning"::string = 'Minor Axis in 3D Length'
             THEN QUANT."Value" END)                       AS "Max_MinorAxis3DLength",
             
    MAX(CASE WHEN QUANT."Quantity":"CodeMeaning"::string = 'Sphericity'
             THEN QUANT."Value" END)                       AS "Max_Sphericity",
             
    MAX(CASE WHEN QUANT."Quantity":"CodeMeaning"::string = 'Surface area of mesh'
             THEN QUANT."Value" END)                       AS "Max_SurfaceAreaMesh",
             
    MAX(CASE WHEN QUANT."Quantity":"CodeMeaning"::string = 'Surface to Volume Ratio'
             THEN QUANT."Value" END)                       AS "Max_SurfaceToVolumeRatio",
             
    MAX(CASE WHEN QUANT."Quantity":"CodeMeaning"::string = 'Volume from Voxel Summation'
             THEN QUANT."Value" END)                       AS "Max_VolumeVoxelSummation",
             
    MAX(CASE WHEN QUANT."Quantity":"CodeMeaning"::string = 'Volume of Mesh'
             THEN QUANT."Value" END)                       AS "Max_VolumeMesh"
             
FROM
    IDC.IDC_V17.DICOM_ALL                       AS D
JOIN
    IDC.IDC_V17.QUANTITATIVE_MEASUREMENTS       AS QUANT
      ON QUANT."segmentationInstanceUID" = D."SOPInstanceUID"
WHERE
      D."StudyDate" IS NOT NULL
  AND EXTRACT(YEAR FROM D."StudyDate") = 2001
GROUP BY
    D."PatientID",
    D."StudyInstanceUID",
    D."StudyDate",
    QUANT."findingSite":"CodeMeaning"::string
ORDER BY
    D."PatientID",
    D."StudyInstanceUID";