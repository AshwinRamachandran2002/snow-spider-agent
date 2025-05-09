SELECT DISTINCT d."StudyInstanceUID"
FROM (
    SELECT DISTINCT "StudyInstanceUID"
    FROM "IDC"."IDC_V17"."DICOM_ALL"
    WHERE LOWER("collection_name") = 'qin-prostate-repeatability'
      AND "Modality" = 'MR'
      AND "SeriesDescription" ILIKE '%t2%'
      AND "SeriesDescription" ILIKE '%axial%'
) AS d
JOIN "IDC"."IDC_V17"."SEGMENTATIONS" AS s
  ON d."StudyInstanceUID" = s."StudyInstanceUID"
WHERE LOWER(s."SegmentedPropertyType":"CodeMeaning"::STRING) ILIKE '%peripheral%zone%';