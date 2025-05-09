SELECT COUNT(DISTINCT s."StudyInstanceUID") AS "Total_Count_of_StudyInstanceUIDs"
FROM IDC.IDC_V17.SEGMENTATIONS s
JOIN IDC.IDC_V17.DICOM_PIVOT d
ON s."StudyInstanceUID" = d."StudyInstanceUID"
WHERE s."SegmentedPropertyType":CodeValue::STRING = '15825003'
AND LOWER(d."collection_id") IN ('colorectal_liver_metastases', 'nsclc_radiomics');