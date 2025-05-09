SELECT
    SUM(TRY_TO_NUMBER("NumberOfFrames")) AS "total_frames"
FROM
    "IDC"."IDC_V17"."DICOM_ALL"
WHERE
    LOWER("collection_id") = 'tcga_brca'                -- TCGA-BRCA collection
    AND "Modality" = 'SM'                               -- whole-slide microscopy
    AND "NumberOfFrames" IS NOT NULL                    -- frame count present
    AND "SpecimenDescriptionSequence" IS NOT NULL       -- has specimen prep details
    AND TO_VARCHAR("SpecimenDescriptionSequence") ILIKE '%eosin%'  -- eosin staining step
;