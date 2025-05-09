SELECT 
    COUNT(DISTINCT "StudyInstanceUID") AS "num_unique_studies"
FROM IDC.IDC_V17.DICOM_PIVOT
WHERE 
      TRIM(UPPER("SegmentedPropertyTypeCodeSequence")) = '15825003'
  AND LOWER("collection_id") IN ('community', 'nsclc_radiomics');