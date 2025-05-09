-- Total number of frames across unique whole‑slide microscopy (SM) instances
-- from the TCGA‑BRCA collection whose specimen description mentions “eosin”
SELECT
  SUM(TRY_TO_NUMBER("NumberOfFrames")) AS "total_frames_eosin_sm"
FROM (
  SELECT DISTINCT
         "SOPInstanceUID",
         "NumberOfFrames"
  FROM IDC.IDC_V17.DICOM_ALL
  WHERE "collection_id" = 'tcga_brca'
    AND "Modality" = 'SM'
    AND "SpecimenDescriptionSequence" ILIKE '%eosin%'
) t;