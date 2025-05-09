SELECT
    COUNT(DISTINCT "StudyInstanceUID") AS "unique_StudyInstanceUIDs"
FROM
    IDC.IDC_V17.DICOM_ALL
WHERE
    "collection_id" = 'qin_prostate_repeatability'
    AND (
            /* DWI series */
            "SeriesDescription" ILIKE '%DWI%'
         /* Apparent Diffusion Coefficient series */
         OR "SeriesDescription" ILIKE '%Apparent%Diffusion%Coefficient%'
         /* T2-Weighted Axial images */
         OR "SeriesDescription" ILIKE '%T2%Weighted%Axial%'
         /* T2-Weighted Axial segmentations (SEG modality) */
         OR ( "Modality" = 'SEG'
              AND "SeriesDescription" ILIKE '%T2%Weighted%Axial%' )
        );