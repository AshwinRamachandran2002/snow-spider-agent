SELECT 
  COUNT(DISTINCT "StudyInstanceUID") AS "n_unique_studyuids"
FROM 
  IDC.IDC_V17.DICOM_PIVOT
WHERE 
  UPPER(TRIM("SegmentedPropertyTypeCodeSequence")) = '15825003'
  AND LOWER("collection_id") IN ('community', 'nsclc_radiomics');