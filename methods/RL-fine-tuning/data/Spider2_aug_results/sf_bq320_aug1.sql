-- Task: In the dicom_pivot table, list all unique StudyInstanceUID values that exactly match the SegmentedPropertyTypeCodeSequence of "15825003" (case-insensitive) and also have a collection_id of either "Community" or "nsclc_radiomics".

SELECT DISTINCT "StudyInstanceUID"
FROM IDC.IDC_V17.DICOM_PIVOT AS "dicom_pivot"
WHERE LOWER("dicom_pivot"."SegmentedPropertyTypeCodeSequence") LIKE LOWER('15825003')
  AND "dicom_pivot"."collection_id" IN ('Community', 'nsclc_radiomics');