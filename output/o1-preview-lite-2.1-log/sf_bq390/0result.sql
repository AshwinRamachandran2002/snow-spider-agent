SELECT DISTINCT dp."StudyInstanceUID"
FROM IDC.IDC_V17."DICOM_PIVOT" dp
JOIN IDC.IDC_V17."SEGMENTATIONS" seg ON dp."StudyInstanceUID" = seg."StudyInstanceUID"
WHERE dp."collection_id" = 'qin_prostate_repeatability'
  AND dp."Modality" = 'MR'
  AND dp."SeriesDescription" ILIKE '%T2%'
  AND seg."SegmentedPropertyType":CodeMeaning::STRING ILIKE '%Peripheral zone%'