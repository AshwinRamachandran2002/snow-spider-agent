SELECT COUNT(DISTINCT "StudyInstanceUID") AS "unique_study_count"
FROM   "IDC"."IDC_V17"."DICOM_PIVOT"
WHERE  "collection_id" = 'qin_prostate_repeatability'
  AND (
        "SeriesDescription" ILIKE '%DWI%'                                   -- Diffusion-weighted imaging
     OR "SeriesDescription" ILIKE '%T2%Weighted%Axial%'                     -- T2-weighted axial
     OR "SeriesDescription" ILIKE '%Apparent%Diffusion%Coefficient%'        -- ADC maps
     OR "SeriesDescription" ILIKE '%T2%Weighted%Axial%Segment%'             -- T2-weighted axial segmentations
      );