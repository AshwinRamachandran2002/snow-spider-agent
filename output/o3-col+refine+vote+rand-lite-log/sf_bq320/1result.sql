SELECT
    COUNT(DISTINCT dp."StudyInstanceUID") AS "unique_studyinstanceuid_cnt"
FROM
    IDC.IDC_V17."DICOM_PIVOT" AS dp,
    LATERAL SPLIT_TO_TABLE(LOWER(dp."SegmentedPropertyTypeCodeSequence"), ',') AS s
WHERE
    LOWER(TRIM(dp."collection_id")) IN ('community', 'nsclc_radiomics')
    AND TRIM(s.value) = '15825003';