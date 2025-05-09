SELECT COUNT(DISTINCT "StudyInstanceUID") AS "unique_study_count"
FROM   IDC.IDC_V17.DICOM_PIVOT
WHERE  "collection_id" = 'qin_prostate_repeatability'
  AND (
        /* DWI series */
        "SeriesDescription" ILIKE '%DWI%' 
    
        /* Axial T2-weighted series */
        OR "SeriesDescription" ILIKE '%T2 Weighted Axial%'
    
        /* Apparent Diffusion Coefficient (ADC) maps */
        OR "SeriesDescription" ILIKE '%Apparent Diffusion Coefficient%'
    
        /* T2-weighted axial segmentations */
        OR ( "Modality" = 'SEG'
             AND "SeriesDescription" ILIKE '%T2%'
             AND "SeriesDescription" ILIKE '%Axial%' )
      );