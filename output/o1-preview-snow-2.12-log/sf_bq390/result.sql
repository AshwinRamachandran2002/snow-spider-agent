SELECT DISTINCT dp."StudyInstanceUID"
FROM IDC.IDC_V17.DICOM_PIVOT dp
JOIN IDC.IDC_V17.SEGMENTATIONS seg ON dp."StudyInstanceUID" = seg."StudyInstanceUID"
JOIN LATERAL FLATTEN(input => seg."SegmentedPropertyType") f
WHERE dp."collection_id" = 'qin_prostate_repeatability'
  AND dp."SeriesDescription" ILIKE '%T2%'
  AND dp."Modality" = 'MR'
  AND f.value::string ILIKE '%Peripheral zone%'