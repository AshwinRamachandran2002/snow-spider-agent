SELECT
    SUM(TRY_CAST("NumberOfFrames" AS INTEGER)) AS "total_frames"
FROM
    IDC.IDC_V17.DICOM_ALL
WHERE
    "collection_name" = 'TCGA-BRCA'
    AND "Modality" = 'SM'
    AND "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.77.1.6'  -- VL Whole‑Slide Microscopy Image Storage
    AND LOWER(TO_VARCHAR("SpecimenDescriptionSequence")) LIKE '%eosin%'
;