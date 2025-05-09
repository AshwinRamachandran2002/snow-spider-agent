WITH labeled_sequences AS (
    SELECT
        CASE
            WHEN LOWER("SeriesDescription") LIKE '%t2_tse_tra%'      THEN 't2w_prostateX'
            WHEN UPPER("SeriesDescription") LIKE '%ADC%'            THEN 'adc_prostateX'
        END                                                     AS "label",
        TRY_TO_DOUBLE("RepetitionTime")                          AS "RepetitionTime_num",
        TRY_TO_DOUBLE("EchoTime")                                AS "EchoTime_num",
        TRY_TO_DOUBLE("SliceThickness")                          AS "SliceThickness_num"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'prostatex'
      AND "Modality" = 'MR'
      AND (
            LOWER("SeriesDescription") LIKE '%t2_tse_tra%'
         OR UPPER("SeriesDescription") LIKE '%ADC%'
      )
)
SELECT
    AVG("RepetitionTime_num")   AS "avg_RepetitionTime",
    AVG("EchoTime_num")         AS "avg_EchoTime",
    AVG("SliceThickness_num")   AS "avg_SliceThickness",
    AVG("RepetitionTime_num") + 
    AVG("EchoTime_num")       + 
    AVG("SliceThickness_num")   AS "combined_overall_average"
FROM labeled_sequences;