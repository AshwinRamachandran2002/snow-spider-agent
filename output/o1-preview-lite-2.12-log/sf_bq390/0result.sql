SELECT DISTINCT t1."StudyInstanceUID"
FROM IDC.IDC_V17."DICOM_PIVOT" t1
JOIN IDC.IDC_V17."SEGMENTATIONS" t2
  ON t1."StudyInstanceUID" = t2."StudyInstanceUID"
WHERE t1."collection_id" = 'qin_prostate_repeatability'
  AND t1."SeriesDescription" ILIKE '%T2%'
  AND t1."Modality" = 'MR'
  AND t2."SegmentedPropertyType"::STRING ILIKE '%Peripheral zone%'