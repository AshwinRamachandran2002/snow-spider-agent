SELECT
    COUNT(DISTINCT "StudyInstanceUID") AS "unique_study_count"
FROM
    IDC.IDC_V17.DICOM_PIVOT
WHERE
    "collection_id" = 'qin_prostate_repeatability'
    AND (
            -- Diffusion‑weighted imaging series
            UPPER("SeriesDescription") LIKE '%DWI%'
         -- Apparent Diffusion Coefficient series
         OR UPPER("SeriesDescription") LIKE '%APPARENT DIFFUSION COEFFICIENT%'
         OR UPPER("SeriesDescription") LIKE '%ADC%'
         -- T2‑weighted axial series
         OR (UPPER("SeriesDescription") LIKE '%T2%' AND UPPER("SeriesDescription") LIKE '%AX%')
         -- T2‑weighted axial segmentations (SEG modality)
         OR ("Modality" = 'SEG' AND UPPER("SeriesDescription") LIKE '%T2%')
        );