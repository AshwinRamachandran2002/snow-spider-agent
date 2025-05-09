WITH labeled_sequences AS (
    SELECT
        /* assign sequence labels */
        CASE
            WHEN LOWER("SeriesDescription") LIKE '%t2_tse_tra%' THEN 't2w_prostateX'
            WHEN UPPER("SeriesDescription") LIKE '%ADC%'        THEN 'adc_prostateX'
        END                                                  AS sequence_label,
        /* cast numeric‐like text columns safely to numbers */
        TRY_TO_DOUBLE("RepetitionTime")                      AS repetition_time,
        TRY_TO_DOUBLE("EchoTime")                            AS echo_time,
        TRY_TO_DOUBLE("SliceThickness")                      AS slice_thickness
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE LOWER("collection_id") = 'prostatex'
      AND "Modality" = 'MR'
      AND (
            LOWER("SeriesDescription") LIKE '%t2_tse_tra%'   -- t2-weighted
         OR UPPER("SeriesDescription") LIKE '%ADC%'          -- ADC maps
      )
)

SELECT
    AVG(repetition_time)                                                  AS overall_avg_repetition_time,
    AVG(echo_time)                                                        AS overall_avg_echo_time,
    AVG(slice_thickness)                                                  AS overall_avg_slice_thickness,
    AVG(repetition_time) + AVG(echo_time) + AVG(slice_thickness)          AS combined_overall_average
FROM labeled_sequences;