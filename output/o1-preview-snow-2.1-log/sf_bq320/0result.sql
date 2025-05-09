SELECT COUNT(DISTINCT t."StudyInstanceUID") AS "Total_Count_of_StudyInstanceUIDs"
FROM "IDC"."IDC_V17"."SEGMENTATIONS" t
JOIN "IDC"."IDC_V17"."DICOM_PIVOT" p
  ON t."SeriesInstanceUID" = p."SeriesInstanceUID"
WHERE t."SegmentedPropertyType":"CodeValue"::STRING = '15825003'
  AND p."collection_id" IN ('Community', 'nsclc_radiomics');