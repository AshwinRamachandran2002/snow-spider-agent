/*  Average TR, TE, ST for the two prostateX MR sequence types
    and their combined overall average                                    */

WITH labeled AS (
    /*--- tag each MR instance in the prostatex collection --------------*/
    SELECT
        CASE
            WHEN "SeriesDescription" ILIKE '%t2_tse_tra%' THEN 't2w_prostateX'
            WHEN "SeriesDescription" ILIKE '%ADC%'        THEN 'adc_prostateX'
        END                                   AS "sequence_label",
        TRY_TO_DOUBLE("RepetitionTime")       AS "RepetitionTime",
        TRY_TO_DOUBLE("EchoTime")             AS "EchoTime",
        TRY_TO_DOUBLE("SliceThickness")       AS "SliceThickness"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'prostatex'
      AND "Modality"      = 'MR'
      AND (   "SeriesDescription" ILIKE '%t2_tse_tra%'
           OR "SeriesDescription" ILIKE '%ADC%' )
),
/*--- average TR / TE / ST per label ------------------------------------*/
per_label AS (
    SELECT
        "sequence_label",
        AVG("RepetitionTime")  AS "avg_RepetitionTime",
        AVG("EchoTime")        AS "avg_EchoTime",
        AVG("SliceThickness")  AS "avg_SliceThickness"
    FROM labeled
    GROUP BY "sequence_label"
),
/*--- combined overall average ------------------------------------------*/
combined AS (
    SELECT
        'combined_overall_average' AS "sequence_label",
        NULL::DOUBLE               AS "avg_RepetitionTime",
        NULL::DOUBLE               AS "avg_EchoTime",
        NULL::DOUBLE               AS "avg_SliceThickness",
        SUM("avg_RepetitionTime" + "avg_EchoTime" + "avg_SliceThickness")
                                   AS "combined_overall_average"
    FROM per_label
)

/*--- final result : per–label averages plus the combined value ---------*/
SELECT
    "sequence_label",
    "avg_RepetitionTime",
    "avg_EchoTime",
    "avg_SliceThickness",
    NULL::DOUBLE                 AS "combined_overall_average"
FROM per_label

UNION ALL

SELECT
    "sequence_label",
    "avg_RepetitionTime",
    "avg_EchoTime",
    "avg_SliceThickness",
    "combined_overall_average"
FROM combined;