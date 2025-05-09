WITH merged_records AS (
    /* merge INPUTS and OUTPUTS, label the record source */
    SELECT 
        "block_timestamp",
        TO_DOUBLE("value")               AS "value",
        'output'                         AS "record_type"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS"
    
    UNION ALL
    
    SELECT 
        "block_timestamp",
        TO_DOUBLE("value")               AS "value",
        'input'                          AS "record_type"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS"
),

/* yearly average based on the (merged) OUTPUT records */
outputs_year AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP("block_timestamp" / 1000000), 'YYYY')  AS "year",
        AVG("value")                                                AS "avg_output_value"
    FROM merged_records
    WHERE "record_type" = 'output'
    GROUP BY "year"
),

/* yearly average taken directly from the TRANSACTIONS table */
tx_year AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP("block_timestamp" / 1000000), 'YYYY')  AS "year",
        AVG(TO_DOUBLE("output_value"))                              AS "avg_tx_output_value"
    FROM CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    GROUP BY "year"
)

/* difference between the two methods for years present in both */
SELECT
    o."year",
    o."avg_output_value" - t."avg_tx_output_value"  AS "difference_output_minus_tx"
FROM outputs_year o
JOIN tx_year     t  ON o."year" = t."year"
ORDER BY o."year";