SELECT
  SUM(TO_NUMBER("NumberOfFrames")) AS "total_frames_eosin_tcga_brca_sm"
FROM IDC.IDC_V17.DICOM_ALL
WHERE "collection_id" = 'tcga_brca'
  AND "Modality" = 'SM'
  AND LOWER(CAST("SpecimenDescriptionSequence" AS STRING)) LIKE '%eosin%';