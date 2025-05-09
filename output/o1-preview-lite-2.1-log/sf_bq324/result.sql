SELECT SUM(d."NumberOfFrames"::INT) AS "Total_number_of_frames"
FROM IDC.IDC_V17.DICOM_ALL d
JOIN IDC.IDC_V17.DICOM_METADATA_CURATED_SERIES_LEVEL c
  ON d."SeriesInstanceUID" = c."SeriesInstanceUID"
WHERE d."collection_id" = 'tcga_brca'
  AND d."Modality" = 'SM'
  AND c."illuminationType_CodeMeaning" = 'Brightfield illumination';