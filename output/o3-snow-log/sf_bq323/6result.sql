WITH prostatex_sequences AS (
    SELECT
        CASE
            WHEN LOWER("SeriesDescription") LIKE '%t2_tse_tra%' THEN 't2w_prostateX'
            WHEN LOWER("SeriesDescription") LIKE '%adc%'       THEN 'adc_prostateX'
        END                                                    AS "sequence_label",
        TRY_TO_DOUBLE("RepetitionTime")                        AS "RepetitionTime",
        TRY_TO_DOUBLE("EchoTime")                              AS "EchoTime",
        TRY_TO_DOUBLE("SliceThickness")                        AS "SliceThickness"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE LOWER("collection_id") = 'prostatex'
      AND "Modality" = 'MR'
      AND (LOWER("SeriesDescription") LIKE '%t2_tse_tra%' OR
           LOWER("SeriesDescription") LIKE '%adc%')
)

SELECT
    "sequence_label",
    AVG("RepetitionTime")          AS "avg_repetition_time",
    AVG("EchoTime")                AS "avg_echo_time",
    AVG("SliceThickness")          AS "avg_slice_thickness",
    AVG("RepetitionTime") + 
    AVG("EchoTime") + 
    AVG("SliceThickness")          AS "combined_overall_average"
FROM prostatex_sequences
GROUP BY "sequence_label";