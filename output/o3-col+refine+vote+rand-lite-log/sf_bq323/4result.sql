WITH labeled_sequences AS (
    SELECT
        CASE
            WHEN "SeriesDescription" ILIKE '%t2_tse_tra%' THEN 't2w_prostateX'
            WHEN "SeriesDescription" ILIKE '%adc%'        THEN 'adc_prostateX'
        END                                                     AS "sequence_label",
        TRY_TO_DOUBLE("RepetitionTime")                         AS "RepetitionTime_num",
        TRY_TO_DOUBLE("EchoTime")                               AS "EchoTime_num",
        TRY_TO_DOUBLE("SliceThickness")                         AS "SliceThickness_num"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'prostatex'
      AND "Modality" = 'MR'
      AND (
            "SeriesDescription" ILIKE '%t2_tse_tra%' OR
            "SeriesDescription" ILIKE '%adc%'
          )
),
seq_avgs AS (
    SELECT
        "sequence_label",
        AVG("RepetitionTime_num") AS "avg_TR",
        AVG("EchoTime_num")       AS "avg_TE",
        AVG("SliceThickness_num") AS "avg_Slice"
    FROM labeled_sequences
    GROUP BY "sequence_label"
)
SELECT
    SUM("avg_TR" + "avg_TE" + "avg_Slice") AS "combined_overall_average"
FROM seq_avgs;