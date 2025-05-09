WITH labeled_sequences AS (
    SELECT
        CASE 
            WHEN "SeriesDescription" ILIKE '%t2_tse_tra%' THEN 't2w_prostateX'
            WHEN "SeriesDescription" ILIKE '%adc%'        THEN 'adc_prostateX'
        END                                                  AS "seq_label",
        TRY_TO_NUMBER("RepetitionTime")                      AS "rep_time",
        TRY_TO_NUMBER("EchoTime")                            AS "echo_time",
        TRY_TO_NUMBER("SliceThickness")                      AS "slice_thickness"
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  "collection_id" = 'prostatex'
      AND  "Modality" = 'MR'
      AND ( "SeriesDescription" ILIKE '%t2_tse_tra%' 
            OR "SeriesDescription" ILIKE '%adc%' )
)
SELECT
    "seq_label",
    AVG("rep_time")         AS "avg_RepetitionTime",
    AVG("echo_time")        AS "avg_EchoTime",
    AVG("slice_thickness")  AS "avg_SliceThickness",
    AVG("rep_time") + AVG("echo_time") + AVG("slice_thickness")
                            AS "combined_overall_average"
FROM   labeled_sequences
GROUP  BY "seq_label";