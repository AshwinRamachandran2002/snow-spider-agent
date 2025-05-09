SELECT 
    COUNT(DISTINCT "StudyInstanceUID") AS "Unique_StudyInstanceUIDs"
FROM   IDC.IDC_V17.DICOM_ALL
WHERE  ( "collection_name" = 'QIN-PROSTATE-Repeatability' 
      OR "collection_id"   = 'qin_prostate_repeatability' )
  AND (
        -- Diffusion-weighted imaging series
        "SeriesDescription" ILIKE '%dwi%'                                   -- DWI
     OR -- Apparent Diffusion Coefficient series
        "SeriesDescription" ILIKE '%apparent%diffusion%coefficient%'        -- long form
     OR "SeriesDescription" ILIKE '%adc%'                                   -- short form
     OR -- T2-weighted axial images (exclude segmentations here)
        ( "SeriesDescription" ILIKE '%t2%axial%' AND "Modality" <> 'SEG' )
     OR -- T2-weighted axial segmentations
        ( "Modality" = 'SEG'            AND "SeriesDescription" ILIKE '%t2%axial%' )
      );