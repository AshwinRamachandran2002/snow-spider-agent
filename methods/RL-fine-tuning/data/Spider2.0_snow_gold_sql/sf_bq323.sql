SELECT ROUND(AVG(value), 4) AS "Combined_Overall_Average"
FROM (
    SELECT CAST("RepetitionTime" AS FLOAT) AS value, "collection_id", "Modality", "SeriesDescription"
    FROM IDC.IDC_V17.DICOM_ALL

    UNION ALL

    SELECT CAST("EchoTime" AS FLOAT) AS value, "collection_id", "Modality", "SeriesDescription"
    FROM IDC.IDC_V17.DICOM_ALL

    UNION ALL

    SELECT CAST("SliceThickness" AS FLOAT) AS value, "collection_id", "Modality", "SeriesDescription"
    FROM IDC.IDC_V17.DICOM_ALL
) sub
WHERE "collection_id" = 'prostatex' AND "Modality" = 'MR'
    AND ("SeriesDescription" ILIKE '%t2_tse_tra%' OR "SeriesDescription" ILIKE '%ADC%')
    AND value IS NOT NULL;