-- Total number of frames across TCGA-BRCA whole-slide microscopy (SM) images
-- whose SpecimenPreparationSequence contains an eosin-based staining step
SELECT
  SUM(TO_NUMBER("NumberOfFrames")) AS "total_eosin_frames_TCGA_BRCA_SM"
FROM IDC.IDC_V17.DICOM_ALL
WHERE "collection_id" = 'tcga_brca'
  AND "Modality"      = 'SM'
  -- look for the word 'eosin' anywhere in the SpecimenPreparationSequence
  AND LOWER("SpecimenDescriptionSequence"::STRING) LIKE '%eosin%';