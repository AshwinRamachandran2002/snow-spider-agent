WITH labeled_sequences AS (
    SELECT
        CASE
            WHEN LOWER("SeriesDescription") LIKE '%t2_tse_tra%' THEN 't2w_prostateX'
            WHEN UPPER("SeriesDescription") LIKE '%ADC%'       THEN 'adc_prostateX'
        END                                AS "sequence_label",
        TRY_TO_NUMBER("RepetitionTime")    AS rep_time,
        TRY_TO_NUMBER("EchoTime")          AS echo_time,
        TRY_TO_NUMBER("SliceThickness")    AS slice_thickness
    FROM IDC.IDC_V17."DICOM_ALL"
    WHERE "collection_id" = 'prostatex'
      AND "Modality" = 'MR'
      AND (
            LOWER("SeriesDescription") LIKE '%t2_tse_tra%'
         OR UPPER("SeriesDescription") LIKE '%ADC%'
      )
)
SELECT
    ROUND(AVG(rep_time),       4) AS "average_RepetitionTime",
    ROUND(AVG(echo_time),      4) AS "average_EchoTime",
    ROUND(AVG(slice_thickness),4) AS "average_SliceThickness",
    ROUND(
        AVG(rep_time) + AVG(echo_time) + AVG(slice_thickness),
        4
    ) AS "combined_overall_average"
FROM labeled_sequences;