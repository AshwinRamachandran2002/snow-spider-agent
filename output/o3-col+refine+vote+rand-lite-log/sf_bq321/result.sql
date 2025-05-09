SELECT 
    COUNT(DISTINCT "StudyInstanceUID") AS "unique_study_uids"
FROM 
    IDC.IDC_V17.DICOM_PIVOT
WHERE 
    "collection_id" = 'qin_prostate_repeatability'
    AND (
           "SeriesDescription" ILIKE '%dwi%'                                      -- DWI
        OR ("Modality" = 'MR'  AND "SeriesDescription" ILIKE '%t2%ax%')          -- T2 Weighted Axial MR
        OR ("SeriesDescription" ILIKE '%adc%' 
            OR "SeriesDescription" ILIKE '%apparent%diffusion%coefficient%')     -- Apparent Diffusion Coefficient
        OR ("Modality" = 'SEG' AND "SeriesDescription" ILIKE '%t2%ax%')          -- T2 Weighted Axial Segmentations
    );