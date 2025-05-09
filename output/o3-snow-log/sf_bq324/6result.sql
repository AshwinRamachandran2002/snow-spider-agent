SELECT
    SUM(TRY_TO_NUMBER("NumberOfFrames")) AS total_frames
FROM
    IDC.IDC_V17.DICOM_ALL
WHERE
    "Modality" = 'SM'
    AND LOWER("collection_id") = 'tcga_brca'
    AND "SpecimenDescriptionSequence" IS NOT NULL
    AND LOWER(TO_VARCHAR("SpecimenDescriptionSequence")) LIKE '%eosin%'
;