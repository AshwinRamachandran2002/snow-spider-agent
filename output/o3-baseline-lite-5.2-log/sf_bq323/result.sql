WITH filtered AS (
    SELECT 
        CASE 
            WHEN LOWER("SeriesDescription") LIKE '%t2_tse_tra%' THEN 't2w_prostateX'
            WHEN UPPER("SeriesDescription") LIKE '%ADC%'        THEN 'adc_prostateX'
        END                                           AS label,
        TRY_CAST("RepetitionTime"  AS FLOAT)          AS repetition_time,
        TRY_CAST("EchoTime"        AS FLOAT)          AS echo_time,
        TRY_CAST("SliceThickness"  AS FLOAT)          AS slice_thickness
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  LOWER("collection_id") = 'prostatex'          -- within the ProstateX collection
      AND  "Modality" = 'MR'                             -- MRI sequences only
      AND ( "SeriesDescription" ILIKE '%t2_tse_tra%'     -- sequences of interest
            OR "SeriesDescription" ILIKE '%ADC%' )
)
SELECT
    AVG(repetition_time)  AS avg_repetition_time,
    AVG(echo_time)        AS avg_echo_time,
    AVG(slice_thickness)  AS avg_slice_thickness,
    AVG(repetition_time) + AVG(echo_time) + AVG(slice_thickness) 
                         AS combined_overall_average
FROM filtered;