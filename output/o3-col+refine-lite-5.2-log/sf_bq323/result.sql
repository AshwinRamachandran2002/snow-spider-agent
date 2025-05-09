WITH labeled_sequences AS (
    SELECT
        /* Assign sequence labels                                                      */
        CASE
            WHEN "SeriesDescription" ILIKE '%t2_tse_tra%' THEN 't2w_prostateX'
            WHEN "SeriesDescription" ILIKE '%adc%'        THEN 'adc_prostateX'
        END                                                               AS "sequence_label",
        /* Cast text fields that hold numbers to numeric types for aggregation         */
        TRY_TO_DOUBLE("RepetitionTime")                                   AS "repetition_time_ms",
        TRY_TO_DOUBLE("EchoTime")                                         AS "echo_time_ms",
        TRY_TO_DOUBLE("SliceThickness")                                   AS "slice_thickness_mm"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'prostatex'          -- limit to the PROSTATEx collection
      AND "Modality"      = 'MR'                 -- only MRI sequences
      AND (                                              -- keep only the two target sequence types
            "SeriesDescription" ILIKE '%t2_tse_tra%'
         OR "SeriesDescription" ILIKE '%adc%'
          )
)
SELECT
    AVG("repetition_time_ms")    AS "avg_RepetitionTime_ms",
    AVG("echo_time_ms")          AS "avg_EchoTime_ms",
    AVG("slice_thickness_mm")    AS "avg_SliceThickness_mm",
    -- Sum of the three averages = combined overall average
    (   AVG("repetition_time_ms")
      + AVG("echo_time_ms")
      + AVG("slice_thickness_mm")
    )                            AS "combined_overall_average"
FROM labeled_sequences;