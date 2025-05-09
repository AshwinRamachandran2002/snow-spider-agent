SELECT 
    COUNT(DISTINCT "StudyInstanceUID") AS "unique_study_count"
FROM 
    IDC.IDC_V17.DICOM_PIVOT
WHERE 
    "SegmentedPropertyTypeCodeSequence" ILIKE '15825003'
    AND "collection_id" IN ('Community', 'nsclc_radiomics');