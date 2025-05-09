SELECT
    SUM(TRY_TO_NUMBER("NumberOfFrames")) AS "total_frames"
FROM
    "IDC"."IDC_V17"."DICOM_ALL"
WHERE
      LOWER("collection_id") = 'tcga_brca'      -- TCGA-BRCA collection
  AND "Modality" = 'SM'                         -- whole-slide microscopy images
  AND "SpecimenDescriptionSequence" IS NOT NULL -- has specimen data
  AND LOWER(TO_VARCHAR("SpecimenDescriptionSequence")) LIKE '%eosin%' ; -- eosin staining step