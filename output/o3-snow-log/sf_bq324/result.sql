SELECT
  SUM(CAST("NumberOfFrames" AS INTEGER)) AS "total_frames"
FROM
  IDC.IDC_V17.DICOM_ALL
WHERE
      "collection_id" = 'tcga_brca'        -- TCGA-BRCA collection
  AND "Modality"      = 'SM'               -- whole-slide microscopy images
  AND "NumberOfFrames" IS NOT NULL         -- only instances that report a frame count
  AND LOWER(TO_VARCHAR("SpecimenDescriptionSequence")) LIKE '%eosin%'   -- eosin staining step
;