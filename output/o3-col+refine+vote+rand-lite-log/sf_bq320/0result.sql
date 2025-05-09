SELECT COUNT(DISTINCT "StudyInstanceUID") AS "uid_cnt"
FROM "IDC"."IDC_V17"."DICOM_PIVOT"
WHERE UPPER(TRIM("SegmentedPropertyTypeCodeSequence")) = '15825003'
  AND "collection_id" IN ('Community', 'nsclc_radiomics');