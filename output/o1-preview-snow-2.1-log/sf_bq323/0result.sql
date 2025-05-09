SELECT ROUND(AVG(
    (TRY_TO_NUMBER("RepetitionTime") +
     TRY_TO_NUMBER("EchoTime") +
     TRY_TO_NUMBER("SliceThickness")) / 3
), 4) AS "Combined_Overall_Average"
FROM "IDC"."IDC_V17"."DICOM_ALL"
WHERE
    "collection_id" = 'prostatex'
    AND "Modality" = 'MR'
    AND (
        "SeriesDescription" ILIKE '%t2_tse_tra%'
        OR "SeriesDescription" ILIKE '%ADC%'
    )
    AND "RepetitionTime" IS NOT NULL
    AND "EchoTime" IS NOT NULL
    AND "SliceThickness" IS NOT NULL;