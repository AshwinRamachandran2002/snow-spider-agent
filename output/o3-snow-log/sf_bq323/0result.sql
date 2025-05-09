SELECT
    AVG("repetition_time")          AS "avg_repetition_time",
    AVG("echo_time")                AS "avg_echo_time",
    AVG("slice_thickness")          AS "avg_slice_thickness",
    AVG("repetition_time")
  + AVG("echo_time")
  + AVG("slice_thickness")          AS "combined_overall_average"
FROM (
    /* one row per series that meets the labeling rules */
    SELECT DISTINCT
           "SeriesInstanceUID",
           /* assign requested labels (not used in final math but shown for clarity) */
           CASE
               WHEN LOWER("SeriesDescription") LIKE '%t2_tse_tra%' THEN 't2w_prostateX'
               WHEN LOWER("SeriesDescription") LIKE '%adc%'        THEN 'adc_prostateX'
           END                                         AS "sequence_label",
           TRY_TO_DOUBLE("RepetitionTime")             AS "repetition_time",
           TRY_TO_DOUBLE("EchoTime")                   AS "echo_time",
           TRY_TO_DOUBLE("SliceThickness")             AS "slice_thickness"
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  LOWER("collection_id") = 'prostatex'
      AND  "Modality" = 'MR'
      AND (   LOWER("SeriesDescription") LIKE '%t2_tse_tra%'
           OR LOWER("SeriesDescription") LIKE '%adc%' )
) AS seqs;