SELECT (AVG(CAST("RepetitionTime" AS FLOAT)) + AVG(CAST("EchoTime" AS FLOAT)) + AVG(CAST("SliceThickness" AS FLOAT))) / 3 AS "Combined_Overall_Average"
FROM IDC.IDC_V17.DICOM_ALL
WHERE "collection_name" = 'PROSTATEx'
  AND "Modality" = 'MR'
  AND ("SeriesDescription" LIKE '%t2_tse_tra%' OR "SeriesDescription" LIKE '%ADC%')