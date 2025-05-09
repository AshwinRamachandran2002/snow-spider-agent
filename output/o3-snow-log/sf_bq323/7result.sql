WITH filtered_sequences AS (
    SELECT
        CASE
            WHEN LOWER("SeriesDescription") LIKE '%t2_tse_tra%' THEN 't2w_prostateX'
            WHEN UPPER("SeriesDescription") LIKE '%ADC%'       THEN 'adc_prostateX'
        END                                            AS "sequence_label",
        TRY_TO_DOUBLE("RepetitionTime")                AS "RepetitionTime_val",
        TRY_TO_DOUBLE("EchoTime")                      AS "EchoTime_val",
        TRY_TO_DOUBLE("SliceThickness")                AS "SliceThickness_val"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'prostatex'
      AND "Modality" = 'MR'
      AND (
            LOWER("SeriesDescription") LIKE '%t2_tse_tra%'
         OR UPPER("SeriesDescription") LIKE '%ADC%'
          )
)

SELECT
    AVG("RepetitionTime_val")     AS "avg_RepetitionTime",
    AVG("EchoTime_val")           AS "avg_EchoTime",
    AVG("SliceThickness_val")     AS "avg_SliceThickness",
    AVG("RepetitionTime_val")
  + AVG("EchoTime_val")
  + AVG("SliceThickness_val")     AS "combined_overall_average"
FROM filtered_sequences;