WITH filtered AS (
    SELECT
        CASE
            WHEN LOWER("SeriesDescription") LIKE '%t2_tse_tra%' THEN 't2w_prostateX'
            WHEN LOWER("SeriesDescription") LIKE '%adc%'        THEN 'adc_prostateX'
        END                                             AS seq_label,
        TRY_TO_DOUBLE("RepetitionTime")                 AS repetition_time,
        TRY_TO_DOUBLE("EchoTime")                       AS echo_time,
        TRY_TO_DOUBLE("SliceThickness")                 AS slice_thickness
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE LOWER("collection_id") = 'prostatex'
      AND "Modality" = 'MR'
      AND (
            LOWER("SeriesDescription") LIKE '%t2_tse_tra%'
         OR LOWER("SeriesDescription") LIKE '%adc%'
      )
)

SELECT
    ROUND(AVG(repetition_time), 4)        AS avg_repetition_time,
    ROUND(AVG(echo_time),       4)        AS avg_echo_time,
    ROUND(AVG(slice_thickness), 4)        AS avg_slice_thickness,
    ROUND( AVG(repetition_time)
         + AVG(echo_time)
         + AVG(slice_thickness), 4)       AS combined_overall_average
FROM filtered;