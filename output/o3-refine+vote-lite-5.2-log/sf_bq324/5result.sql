SELECT
    SUM(TRY_TO_NUMBER("NumberOfFrames")) AS "total_frames"
FROM
    IDC.IDC_V17.DICOM_ALL
WHERE
      LOWER("collection_id") = 'tcga_brca'               -- TCGA‑BRCA collection
  AND "Modality" = 'SM'                                   -- whole‑slide microscopy modality
  AND "NumberOfFrames" IS NOT NULL                        -- only instances that specify frame count
  AND "SpecimenDescriptionSequence" IS NOT NULL           -- must include specimen description
  AND LOWER("SpecimenDescriptionSequence"::STRING) LIKE '%eosin%'  -- eosin staining step
;