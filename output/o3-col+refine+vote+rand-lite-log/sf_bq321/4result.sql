SELECT
    COUNT(DISTINCT "StudyInstanceUID") AS "unique_study_count"
FROM   IDC.IDC_V17.DICOM_PIVOT
WHERE  "collection_id" = 'qin_prostate_repeatability'
  AND  (
        "SeriesDescription" ILIKE '%DWI%'                                -- DWI series
     OR "SeriesDescription" ILIKE '%Apparent%Diffusion%Coefficient%'     -- ADC series
     OR ("SeriesDescription" ILIKE '%T2%Weighted%Axial%' 
         AND "Modality" <> 'SEG')                                        -- T2 Weighted Axial (non-SEG)
     OR ("SeriesDescription" ILIKE '%T2%Weighted%Axial%' 
         AND "Modality"  = 'SEG')                                        -- T2 Weighted Axial Segmentations
      );