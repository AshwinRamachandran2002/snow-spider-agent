SELECT
  SUM(TRY_TO_NUMBER("NumberOfFrames")) AS "total_frames"
FROM
  "IDC"."IDC_V17"."DICOM_ALL"
WHERE
  "Modality" = 'SM'
  AND "collection_id" = 'tcga_brca'
  AND "SpecimenDescriptionSequence" IS NOT NULL
  AND LOWER(CAST("SpecimenDescriptionSequence" AS VARCHAR)) LIKE '%eosin%'
;