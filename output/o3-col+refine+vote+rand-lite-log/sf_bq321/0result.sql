SELECT COUNT(DISTINCT "StudyInstanceUID") AS "Unique_StudyInstanceUIDs"
FROM IDC.IDC_V17."DICOM_PIVOT"
WHERE "collection_id" = 'qin_prostate_repeatability'
  AND (
       "SeriesDescription" ILIKE '%dwi%'                                   -- DWI series
    OR "SeriesDescription" ILIKE '%t2%weighted%axial segmentation%'        -- T2-weighted axial segmentations
    OR "SeriesDescription" ILIKE '%t2%weighted%axial%'                     -- T2-weighted axial series
    OR "SeriesDescription" ILIKE '%apparent%diffusion%coefficient%'        -- ADC series
      );