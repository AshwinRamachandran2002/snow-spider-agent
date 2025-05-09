SELECT COUNT(DISTINCT "StudyInstanceUID") AS "unique_study_count"
FROM   IDC.IDC_V17.DICOM_PIVOT
WHERE  "collection_id" = 'qin_prostate_repeatability'
  AND (
        /* DWI series */
        "SeriesDescription" ILIKE '%DWI%'                                                       

        /* Apparent Diffusion Coefficient series */
     OR "SeriesDescription" ILIKE '%Apparent Diffusion Coefficient%'                           

        /* T2-Weighted Axial image series (exclude segmentation modality) */
     OR ( "SeriesDescription" ILIKE '%T2%' 
          AND ( "SeriesDescription" ILIKE '%AX%'  OR "SeriesDescription" ILIKE '%Axial%' )
          AND "Modality" <> 'SEG' )

        /* T2-Weighted Axial segmentation series */
     OR ( "Modality" = 'SEG' 
          AND "SeriesDescription" ILIKE '%T2%' 
          AND ( "SeriesDescription" ILIKE '%AX%'  OR "SeriesDescription" ILIKE '%Axial%' ) )
      );