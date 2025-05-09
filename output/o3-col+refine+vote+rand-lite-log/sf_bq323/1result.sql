WITH sequences AS (                                           -- 1. keep only the MR series of interest & label them
    SELECT
        CASE 
            WHEN LOWER("SeriesDescription") LIKE '%t2_tse_tra%' THEN 't2w_prostateX'
            WHEN UPPER("SeriesDescription") LIKE '%ADC%'       THEN 'adc_prostateX'
        END                                        AS "seq_label",
        TRY_TO_NUMBER("RepetitionTime")            AS "rep_time",
        TRY_TO_NUMBER("EchoTime")                  AS "echo_time",
        TRY_TO_NUMBER("SliceThickness")            AS "slice_thickness"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'prostatex'
      AND "Modality"      = 'MR'
      AND (
              LOWER("SeriesDescription") LIKE '%t2_tse_tra%'
           OR UPPER("SeriesDescription") LIKE '%ADC%'
          )
),                                                  -- 2. compute averages per label
stats AS (
    SELECT
        "seq_label",
        AVG("rep_time")       AS "avg_TR",
        AVG("echo_time")      AS "avg_TE",
        AVG("slice_thickness")AS "avg_ST"
    FROM sequences
    GROUP BY "seq_label"
),                                                  -- 3. pivot the two rows into one
pivot AS (
    SELECT
        MAX(CASE WHEN "seq_label" = 't2w_prostateX' THEN "avg_TR" END) AS "avg_TR_t2w",
        MAX(CASE WHEN "seq_label" = 't2w_prostateX' THEN "avg_TE" END) AS "avg_TE_t2w",
        MAX(CASE WHEN "seq_label" = 't2w_prostateX' THEN "avg_ST" END) AS "avg_ST_t2w",
        MAX(CASE WHEN "seq_label" = 'adc_prostateX' THEN "avg_TR" END) AS "avg_TR_adc",
        MAX(CASE WHEN "seq_label" = 'adc_prostateX' THEN "avg_TE" END) AS "avg_TE_adc",
        MAX(CASE WHEN "seq_label" = 'adc_prostateX' THEN "avg_ST" END) AS "avg_ST_adc"
    FROM stats
)
SELECT                                                  -- 4. final result with combined overall average
    "avg_TR_t2w",
    "avg_TE_t2w",
    "avg_ST_t2w",
    "avg_TR_adc",
    "avg_TE_adc",
    "avg_ST_adc",
    ("avg_TR_t2w" + "avg_TE_t2w" + "avg_ST_t2w" +
     "avg_TR_adc" + "avg_TE_adc" + "avg_ST_adc")      AS "combined_overall_average"
FROM pivot;