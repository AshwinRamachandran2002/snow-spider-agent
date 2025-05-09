SELECT COUNT(DISTINCT "StudyInstanceUID") AS "unique_study_count"
FROM   "IDC"."IDC_V17"."DICOM_ALL"
WHERE  "collection_id" = 'qin_prostate_repeatability'
  AND (
        /* DWI series */
        UPPER("SeriesDescription") LIKE '%DWI%'                                                  
        /* Apparent Diffusion Coefficient series */
        OR UPPER("SeriesDescription") LIKE '%APPARENT DIFFUSION COEFFICIENT%'                   
        /* T2‑Weighted Axial image series (non‑SEG modality) */
        OR (UPPER("SeriesDescription") LIKE '%T2%' 
            AND UPPER("SeriesDescription") LIKE '%AXIAL%' 
            AND "Modality" <> 'SEG')                                                            
        /* T2‑Weighted Axial segmentation series (SEG modality) */
        OR (UPPER("SeriesDescription") LIKE '%T2%' 
            AND UPPER("SeriesDescription") LIKE '%AXIAL%' 
            AND "Modality" = 'SEG')                                                             
      );