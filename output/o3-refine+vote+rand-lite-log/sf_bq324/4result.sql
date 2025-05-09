SELECT
  SUM(TRY_TO_NUMBER("NumberOfFrames")) AS "total_frames"
FROM
  IDC.IDC_V17.DICOM_ALL
WHERE
      "collection_id" = 'tcga_brca'
  AND "Modality" = 'SM'
  AND LOWER(TO_VARCHAR("SpecimenDescriptionSequence")) LIKE '%eosin%'
  AND "NumberOfFrames" IS NOT NULL;