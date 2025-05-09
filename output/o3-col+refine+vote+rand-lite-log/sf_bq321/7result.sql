SELECT 
  COUNT(DISTINCT "StudyInstanceUID") AS "num_unique_studies"
FROM IDC.IDC_V17.DICOM_ALL
WHERE "collection_id" = 'qin_prostate_repeatability'
  AND (
        /* DWI series */
        "SeriesDescription" ILIKE '%dwi%'
        
        /* Apparent Diffusion Coefficient series */
        OR "SeriesDescription" ILIKE '%apparent diffusion coefficient%'
        
        /* T2-weighted axial images (exclude segmentations) */
        OR (
             "SeriesDescription" ILIKE '%t2%' 
             AND "SeriesDescription" ILIKE '%axial%' 
             AND "Modality" <> 'SEG'
           )
           
        /* T2-weighted axial segmentations */
        OR (
             "SeriesDescription" ILIKE '%t2%' 
             AND "SeriesDescription" ILIKE '%axial%' 
             AND (
                  "Modality" = 'SEG'
                  OR "SeriesDescription" ILIKE '%segment%'
                  OR "SeriesDescription" ILIKE '%segmentation%'
                 )
           )
      );