WITH labeled AS (
    SELECT
        CASE
            WHEN "SeriesDescription" ILIKE '%t2_tse_tra%' THEN 't2w_prostateX'
            WHEN "SeriesDescription" ILIKE '%adc%'        THEN 'adc_prostateX'
        END                            AS lbl,
        TRY_TO_NUMBER("RepetitionTime") AS TR,
        TRY_TO_NUMBER("EchoTime")       AS TE,
        TRY_TO_NUMBER("SliceThickness") AS SL
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'prostatex'
      AND "Modality" = 'MR'
      AND (
            "SeriesDescription" ILIKE '%t2_tse_tra%'
         OR "SeriesDescription" ILIKE '%adc%'
      )
)

SELECT
    lbl,
    AVG(TR) AS avg_TR,
    AVG(TE) AS avg_TE,
    AVG(SL) AS avg_SliceThickness,
    AVG(TR) + AVG(TE) + AVG(SL) AS combined_overall_average
FROM labeled
GROUP BY lbl
ORDER BY lbl;