SELECT
    COUNT(DISTINCT "StudyInstanceUID") AS "unique_StudyInstanceUIDs"
FROM
    IDC.IDC_V17.DICOM_ALL
WHERE
    "collection_id" = 'qin_prostate_repeatability'
    AND (
            UPPER(COALESCE("SeriesDescription", '')) LIKE '%DWI%'                               -- Diffusion-weighted series
         OR UPPER(COALESCE("SeriesDescription", '')) LIKE '%T2 WEIGHTED AXIAL%'                 -- T2-weighted axial series
         OR UPPER(COALESCE("SeriesDescription", '')) LIKE '%APPARENT DIFFUSION COEFFICIENT%'    -- ADC series
         OR UPPER(COALESCE("SeriesDescription", '')) LIKE '%T2 WEIGHTED AXIAL SEGMENT%'         -- T2-weighted axial segmentations
        );