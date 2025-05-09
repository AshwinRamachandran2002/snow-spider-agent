SELECT 
    COUNT(DISTINCT "StudyInstanceUID") AS "unique_study_count"
FROM 
    IDC.IDC_V17.DICOM_PIVOT
WHERE 
    "collection_id" = 'qin_prostate_repeatability'
    AND (
           UPPER("SeriesDescription") LIKE '%DWI%'                       -- Diffusion-weighted series
        OR UPPER("SeriesDescription") LIKE '%ADC%'                       -- Apparent Diffusion Coefficient series
        OR UPPER("SeriesDescription") LIKE '%APPARENT DIFFUSION%'        -- catch full wording
        OR (UPPER("SeriesDescription") LIKE '%T2%'                       -- T2-weighted axial (images or segmentations)
            AND UPPER("SeriesDescription") LIKE '%AX%')
    );