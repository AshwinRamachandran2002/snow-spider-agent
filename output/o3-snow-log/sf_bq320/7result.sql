SELECT
    COUNT(DISTINCT "StudyInstanceUID") AS "unique_studies"
FROM
    IDC.IDC_V17.DICOM_PIVOT
WHERE
    UPPER(TRIM("SegmentedPropertyTypeCodeSequence")) = '15825003'
    AND "collection_id" IN ('Community', 'nsclc_radiomics');