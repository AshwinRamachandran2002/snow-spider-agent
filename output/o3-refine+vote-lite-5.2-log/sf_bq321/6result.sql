SELECT COUNT(DISTINCT "StudyInstanceUID") AS "unique_study_count"
FROM   IDC.IDC_V17.DICOM_PIVOT
WHERE  "collection_id" = 'qin_prostate_repeatability'
  AND (
        -- DWI series
        UPPER("SeriesDescription") LIKE '%DWI%'
        
        -- T2‑Weighted Axial MR series
        OR ( "Modality" = 'MR'
             AND UPPER("SeriesDescription") LIKE '%T2%'
             AND UPPER("SeriesDescription") LIKE '%AXIAL%' )
             
        -- Apparent Diffusion Coefficient (ADC) series
        OR UPPER("SeriesDescription") LIKE '%APPARENT DIFFUSION COEFFICIENT%'
        OR UPPER("SeriesDescription") LIKE '%ADC%'
        
        -- T2‑Weighted Axial segmentations
        OR ( "Modality" = 'SEG'
             AND UPPER("SeriesDescription") LIKE '%T2%'
             AND UPPER("SeriesDescription") LIKE '%AXIAL%' )
      );