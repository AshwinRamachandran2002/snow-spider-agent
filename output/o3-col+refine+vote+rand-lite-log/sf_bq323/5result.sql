WITH seq AS (
    SELECT
        CASE
            WHEN "SeriesDescription" ILIKE '%t2_tse_tra%' THEN 't2w_prostateX'
            WHEN "SeriesDescription" ILIKE '%adc%'        THEN 'adc_prostateX'
        END                                               AS "label",
        TRY_TO_DOUBLE("RepetitionTime")                   AS "TR",
        TRY_TO_DOUBLE("EchoTime")                         AS "TE",
        TRY_TO_DOUBLE("SliceThickness")                   AS "ST"
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  "collection_id" = 'prostatex'
      AND  "Modality"      = 'MR'
      AND (
              "SeriesDescription" ILIKE '%t2_tse_tra%'
           OR "SeriesDescription" ILIKE '%adc%'
          )
)
SELECT
       AVG("TR") AS "avg_repetition_time",
       AVG("TE") AS "avg_echo_time",
       AVG("ST") AS "avg_slice_thickness",
       ( AVG("TR") + AVG("TE") + AVG("ST") ) AS "combined_overall_average"
FROM   seq;