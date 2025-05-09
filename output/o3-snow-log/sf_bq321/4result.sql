SELECT COUNT(DISTINCT "StudyInstanceUID") AS "unique_study_count"
FROM   IDC.IDC_V17.DICOM_PIVOT
WHERE  "collection_id" = 'qin_prostate_repeatability'
  AND  LOWER("SeriesDescription") IN (
        'dwi',
        't2 weighted axial',
        'apparent diffusion coefficient',
        't2 weighted axial segmentations'
      );