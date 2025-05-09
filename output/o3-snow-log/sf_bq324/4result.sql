SELECT
  SUM(TRY_TO_NUMBER("NumberOfFrames")) AS TOTAL_FRAMES
FROM
  "IDC"."IDC_V17"."DICOM_ALL"
WHERE
      "collection_id" = 'tcga_brca'      -- TCGA-BRCA collection
  AND "Modality"       = 'SM'            -- whole-slide microscopy
  AND "NumberOfFrames" IS NOT NULL
  AND "SpecimenDescriptionSequence" IS NOT NULL          -- contains preparation info
  AND LOWER("SpecimenDescriptionSequence"::STRING) LIKE '%eosin%' ;  -- eosin staining step