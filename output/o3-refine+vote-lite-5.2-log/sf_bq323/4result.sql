WITH prostatex_sequences AS (
    SELECT
        CASE
            WHEN "SeriesDescription" ILIKE '%t2_tse_tra%' THEN 't2w_prostateX'
            WHEN "SeriesDescription" ILIKE '%ADC%'        THEN 'adc_prostateX'
        END                                                             AS "seq_label",
        TRY_TO_DOUBLE("RepetitionTime")                                 AS "rep_time",
        TRY_TO_DOUBLE("EchoTime")                                       AS "echo_time",
        TRY_TO_DOUBLE("SliceThickness")                                 AS "slice_thickness"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE
        "collection_id" = 'prostatex'
        AND "Modality" = 'MR'
        AND (
               "SeriesDescription" ILIKE '%t2_tse_tra%'
            OR "SeriesDescription" ILIKE '%ADC%'
        )
)
SELECT
    ROUND(AVG("rep_time"),          4)  AS "avg_repetition_time",
    ROUND(AVG("echo_time"),         4)  AS "avg_echo_time",
    ROUND(AVG("slice_thickness"),   4)  AS "avg_slice_thickness",
    ROUND(AVG("rep_time") + AVG("echo_time") + AVG("slice_thickness"), 4)
                                        AS "combined_overall_average"
FROM prostatex_sequences;