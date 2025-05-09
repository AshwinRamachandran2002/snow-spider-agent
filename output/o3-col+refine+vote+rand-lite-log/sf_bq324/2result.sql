SELECT
    SUM(TRY_TO_NUMBER("NumberOfFrames")) AS total_frames_eosin_sm_tcga_brca
FROM IDC.IDC_V17.DICOM_ALL
WHERE "collection_id" = 'tcga_brca'
  AND "Modality" = 'SM'
  AND "SpecimenDescriptionSequence" ILIKE '%eosin%'
  AND "NumberOfFrames" IS NOT NULL;