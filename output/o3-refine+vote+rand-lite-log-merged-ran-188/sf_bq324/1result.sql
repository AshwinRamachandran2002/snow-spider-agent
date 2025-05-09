SELECT
    SUM(TRY_TO_NUMBER("NumberOfFrames")) AS total_frames
FROM
    IDC.IDC_V17.DICOM_ALL
WHERE
    "collection_name" = 'TCGA-BRCA'         -- TCGA‑BRCA collection
    AND "Modality" = 'SM'                   -- whole‑slide microscopy images
    AND "NumberOfFrames" IS NOT NULL
    AND "SpecimenDescriptionSequence" IS NOT NULL
    AND LOWER(TO_VARCHAR("SpecimenDescriptionSequence")) LIKE '%eosin%'  -- eosin staining step
;