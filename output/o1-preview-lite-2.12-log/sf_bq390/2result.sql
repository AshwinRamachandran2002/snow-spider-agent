SELECT DISTINCT D."StudyInstanceUID"
FROM "IDC"."IDC_V17"."DICOM_PIVOT" D
JOIN "IDC"."IDC_V17"."SEGMENTATIONS" S
  ON D."StudyInstanceUID" = S."StudyInstanceUID"
WHERE D."collection_id" = 'qin_prostate_repeatability'
  AND D."SeriesDescription" ILIKE '%T2%'
  AND D."Modality" = 'MR'
  AND S."SegmentedPropertyType" ILIKE '%Peripheral zone%'
;