SELECT 
    dm."Modality", 
    COUNT(dm."SOPInstanceUID") AS "TotalSOPInstances"
FROM IDC.IDC_V17.DICOM_METADATA dm
GROUP BY dm."Modality"
ORDER BY COUNT(dm."SOPInstanceUID") DESC NULLS LAST
LIMIT 1;