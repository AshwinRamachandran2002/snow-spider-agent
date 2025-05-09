SELECT
  COUNT(DISTINCT "StudyInstanceUID") AS "unique_study_count"
FROM IDC.IDC_V17.DICOM_PIVOT
WHERE TRIM(LOWER("SegmentedPropertyTypeCodeSequence")) = '15825003'
  AND LOWER("collection_id") IN ('community', 'nsclc_radiomics');