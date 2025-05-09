WITH filtered AS (
    SELECT
        CASE
            WHEN LOWER("SeriesDescription") LIKE '%t2_tse_tra%' THEN 't2w_prostateX'
            WHEN LOWER("SeriesDescription") LIKE '%adc%'        THEN 'adc_prostateX'
        END                                         AS seq_label,
        TRY_TO_NUMBER("RepetitionTime")             AS rep_time,
        TRY_TO_NUMBER("EchoTime")                   AS echo_time,
        TRY_TO_NUMBER("SliceThickness")             AS slice_thk
    FROM "IDC"."IDC_V17"."DICOM_ALL"
    WHERE LOWER("collection_name") = 'prostatex'
      AND "Modality" = 'MR'
      AND (
            LOWER("SeriesDescription") LIKE '%t2_tse_tra%'
         OR LOWER("SeriesDescription") LIKE '%adc%'
      )
)
SELECT 'avg_repetition_time'  AS metric, ROUND(AVG(rep_time),4)                               AS value FROM filtered
UNION ALL
SELECT 'avg_echo_time'        AS metric, ROUND(AVG(echo_time),4)                              AS value FROM filtered
UNION ALL
SELECT 'avg_slice_thickness'  AS metric, ROUND(AVG(slice_thk),4)                              AS value FROM filtered
UNION ALL
SELECT 'combined_overall_avg' AS metric, ROUND(AVG(rep_time)+AVG(echo_time)+AVG(slice_thk),4) AS value FROM filtered
ORDER BY metric;