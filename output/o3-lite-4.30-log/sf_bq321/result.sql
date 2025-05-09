SELECT
  'combined_series' AS series_type,
  COUNT(DISTINCT "StudyInstanceUID") AS unique_studyinstanceuids
FROM (
        /* DWI series */
        SELECT DISTINCT "StudyInstanceUID"
        FROM   "IDC"."IDC_V17"."DICOM_PIVOT"
        WHERE  "collection_id" = 'qin_prostate_repeatability'
          AND  "SeriesDescription" ILIKE '%DWI%'

        UNION

        /* T2 Weighted Axial series */
        SELECT DISTINCT "StudyInstanceUID"
        FROM   "IDC"."IDC_V17"."DICOM_PIVOT"
        WHERE  "collection_id" = 'qin_prostate_repeatability'
          AND  "SeriesDescription" ILIKE '%T2%'
          AND  "SeriesDescription" ILIKE '%AX%'

        UNION

        /* Apparent Diffusion Coefficient (ADC) series */
        SELECT DISTINCT "StudyInstanceUID"
        FROM   "IDC"."IDC_V17"."DICOM_PIVOT"
        WHERE  "collection_id" = 'qin_prostate_repeatability'
          AND ( "SeriesDescription" ILIKE '%Apparent%Diffusion%Coefficient%' 
                OR "SeriesDescription" ILIKE '%ADC%' )

        UNION

        /* T2 Weighted Axial SEG objects (linked via segmented_SeriesInstanceUID) */
        SELECT DISTINCT img."StudyInstanceUID"
        FROM   "IDC"."IDC_V17"."SEGMENTATIONS" seg
        JOIN   "IDC"."IDC_V17"."DICOM_PIVOT" img
               ON seg."segmented_SeriesInstanceUID" = img."SeriesInstanceUID"
        WHERE  img."collection_id" = 'qin_prostate_repeatability'
          AND  img."SeriesDescription" ILIKE '%T2%'
          AND  img."SeriesDescription" ILIKE '%AX%'
) uid_set;