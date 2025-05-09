SELECT COUNT(DISTINCT "StudyInstanceUID") AS "unique_study_count"
FROM   IDC.IDC_V17.DICOM_ALL
WHERE  "collection_id" = 'qin_prostate_repeatability'
  AND  UPPER("SeriesDescription") IN (
        'DWI',
        'T2 WEIGHTED AXIAL',
        'APPARENT DIFFUSION COEFFICIENT',
        'T2 WEIGHTED AXIAL SEGMENTATIONS'
      );