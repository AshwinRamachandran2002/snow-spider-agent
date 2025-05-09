SELECT
    SUM(TRY_TO_NUMBER("NumberOfFrames")) AS total_frames
FROM
    IDC.IDC_V17.DICOM_ALL
WHERE
    "collection_id" = 'tcga_brca'           -- TCGA‑BRCA collection
    AND "Modality" = 'SM'                   -- whole‑slide microscopy images
    AND LOWER("SpecimenDescriptionSequence"::STRING) LIKE '%eosin%'  -- eosin staining step
;