SELECT COUNT(DISTINCT "StudyInstanceUID") AS "unique_study_count"
FROM   IDC.IDC_V17.DICOM_PIVOT
WHERE  "collection_id" = 'qin_prostate_repeatability'
  AND (
        LOWER("SeriesDescription") LIKE '%dwi%'                                        -- DWI series
     OR LOWER("SeriesDescription") LIKE '%apparent%diffusion%coefficient%'            -- ADC series
     OR (LOWER("SeriesDescription") LIKE '%t2%axial%'  AND "Modality" = 'MR')         -- T2-Weighted Axial MR
     OR (LOWER("SeriesDescription") LIKE '%t2%axial%'  AND "Modality" = 'SEG')        -- T2-Weighted Axial Segmentations
      );