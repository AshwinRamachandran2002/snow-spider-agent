WITH filtered AS (
    SELECT
        CASE
             WHEN LOWER("SeriesDescription") LIKE '%t2_tse_tra%'       THEN 't2w_prostateX'
             WHEN UPPER("SeriesDescription") LIKE '%ADC%'              THEN 'adc_prostateX'
        END                                           AS "label",
        TRY_TO_DOUBLE("RepetitionTime")               AS "repetition_time",
        TRY_TO_DOUBLE("EchoTime")                     AS "echo_time",
        TRY_TO_DOUBLE("SliceThickness")               AS "slice_thickness"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'prostatex'
      AND "Modality"      = 'MR'
      AND (
             LOWER("SeriesDescription") LIKE '%t2_tse_tra%' 
          OR UPPER("SeriesDescription") LIKE '%ADC%'
          )
)
SELECT
    ROUND(AVG("repetition_time"), 4)                   AS "avg_RepetitionTime",
    ROUND(AVG("echo_time"),        4)                  AS "avg_EchoTime",
    ROUND(AVG("slice_thickness"),  4)                  AS "avg_SliceThickness",
    ROUND(
          AVG("repetition_time") 
        + AVG("echo_time") 
        + AVG("slice_thickness"), 4)                   AS "combined_overall_average"
FROM filtered;