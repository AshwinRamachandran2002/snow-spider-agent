SELECT COUNT(DISTINCT "StudyInstanceUID") AS "NumberOfUniqueStudyInstanceUIDs"
FROM IDC.IDC_V17.DICOM_ALL
WHERE "collection_id" = 'qin_prostate_repeatability'
  AND (
    "SeriesDescription" LIKE '%DWI%'
    OR "SeriesDescription" LIKE '%T2 Weighted Axial%'
    OR "SeriesDescription" LIKE '%Apparent Diffusion Coefficient%'
    OR "SeriesDescription" = 'T2 Weighted Axial Segmentations'
  );