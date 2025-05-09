WITH labeled AS (
    -- Keep only MR series from the PROSTATEx collection that match either label
    SELECT
        CASE
            WHEN "SeriesDescription" ILIKE '%t2_tse_tra%' THEN 't2w_prostateX'
            WHEN "SeriesDescription" ILIKE '%ADC%'        THEN 'adc_prostateX'
        END                               AS seq_label,
        TRY_TO_NUMBER("RepetitionTime")   AS repetition_time,
        TRY_TO_NUMBER("EchoTime")         AS echo_time,
        TRY_TO_NUMBER("SliceThickness")   AS slice_thickness
    FROM "IDC"."IDC_V17"."DICOM_ALL"
    WHERE "collection_name" = 'PROSTATEx'
      AND "Modality" = 'MR'
      AND (
            "SeriesDescription" ILIKE '%t2_tse_tra%'
            OR "SeriesDescription" ILIKE '%ADC%'
          )
), avgs AS (
    -- Overall averages across both labels
    SELECT
        AVG(repetition_time)  AS avg_repetition_time,
        AVG(echo_time)        AS avg_echo_time,
        AVG(slice_thickness)  AS avg_slice_thickness
    FROM labeled
)
-- Present each metric as a separate csv‑style row
SELECT 'avg_repetition_time'      AS metric, ROUND(avg_repetition_time ,4)                           AS value FROM avgs
UNION ALL
SELECT 'avg_echo_time',                 ROUND(avg_echo_time       ,4)                                FROM avgs
UNION ALL
SELECT 'avg_slice_thickness',           ROUND(avg_slice_thickness ,4)                                FROM avgs
UNION ALL
SELECT 'combined_overall_average',
       ROUND(avg_repetition_time + avg_echo_time + avg_slice_thickness,4)                            FROM avgs;