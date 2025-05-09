-- Count of unique studies that contain at least one of the
-- four requested series types in the qin_prostate_repeatability collection
SELECT
    COUNT(DISTINCT "StudyInstanceUID") AS "unique_study_count"
FROM (
    /* DWI series */
    SELECT "StudyInstanceUID"
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  "collection_id"     = 'qin_prostate_repeatability'
      AND  "SeriesDescription" ILIKE '%DWI%'

    UNION

    /* T2 Weighted Axial series */
    SELECT "StudyInstanceUID"
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  "collection_id"     = 'qin_prostate_repeatability'
      AND  "SeriesDescription" ILIKE '%T2%AX%'

    UNION

    /* Apparent Diffusion Coefficient (ADC) series */
    SELECT "StudyInstanceUID"
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  "collection_id"     = 'qin_prostate_repeatability'
      AND ( "SeriesDescription" ILIKE '%Apparent%Diffusion%Coefficient%'
         OR "SeriesDescription" ILIKE '%ADC%' )

    UNION

    /* T2 Weighted Axial segmentations (SEG modality) */
    SELECT "StudyInstanceUID"
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  "collection_id"     = 'qin_prostate_repeatability'
      AND  "Modality"          = 'SEG'
      AND  "SeriesDescription" ILIKE '%T2%'
) study_union;