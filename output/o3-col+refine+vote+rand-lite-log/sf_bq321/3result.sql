-- Description: Count unique StudyInstanceUIDs that have at least one of the
--              specified series types in the 'qin_prostate_repeatability' collection
SELECT COUNT(DISTINCT "StudyInstanceUID") AS "UniqueStudyCount"
FROM (
        /* DWI series */
        SELECT "StudyInstanceUID"
        FROM   IDC.IDC_V17."DICOM_PIVOT"
        WHERE  "collection_id" = 'qin_prostate_repeatability'
          AND  "SeriesDescription" ILIKE '%dwi%'

        UNION

        /* T2 Weighted Axial series */
        SELECT "StudyInstanceUID"
        FROM   IDC.IDC_V17."DICOM_PIVOT"
        WHERE  "collection_id" = 'qin_prostate_repeatability'
          AND  "SeriesDescription" ILIKE '%t2%weighted%axial%'

        UNION

        /* Apparent Diffusion Coefficient (ADC) series */
        SELECT "StudyInstanceUID"
        FROM   IDC.IDC_V17."DICOM_PIVOT"
        WHERE  "collection_id" = 'qin_prostate_repeatability'
          AND  ( "SeriesDescription" ILIKE '%apparent%diffusion%coefficient%'
                 OR "SeriesDescription" ILIKE '%adc%' )

        UNION

        /* T2 Weighted Axial segmentation series */
        SELECT "StudyInstanceUID"
        FROM   IDC.IDC_V17."DICOM_PIVOT"
        WHERE  "collection_id" = 'qin_prostate_repeatability'
          AND  "Modality" = 'SEG'
          AND  "SeriesDescription" ILIKE '%t2%weighted%axial%'
     ) AS combined;