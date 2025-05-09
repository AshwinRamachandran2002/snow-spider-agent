SELECT
  CASE
    WHEN "SeriesDescription" = 'DWI'                           THEN 'DWI'
    WHEN "SeriesDescription" = 'T2 Weighted Axial'             THEN 'T2 Weighted Axial'
    WHEN "SeriesDescription" = 'Apparent Diffusion Coefficient' THEN 'Apparent Diffusion Coefficient'
    WHEN "SeriesDescription" = 'T2 Weighted Axial Segmentations' THEN 'T2 Weighted Axial Segmentations'
  END AS "series_type",
  COUNT(DISTINCT "StudyInstanceUID") AS "unique_studyinstanceuids"
FROM "IDC"."IDC_V17"."DICOM_PIVOT"
WHERE "collection_id" = 'qin_prostate_repeatability'
  AND "SeriesDescription" IN (
        'DWI',
        'T2 Weighted Axial',
        'Apparent Diffusion Coefficient',
        'T2 Weighted Axial Segmentations'
      )
GROUP BY "series_type"
ORDER BY "series_type";