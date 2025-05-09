WITH merged_io AS (
    /* merge Inputs & Outputs, tag record origin */
    SELECT 
        YEAR( TO_TIMESTAMP("block_timestamp" / 1000000) ) AS "year",
        "value",
        'output'                                          AS "rec_type"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS"
    
    UNION ALL
    
    SELECT 
        YEAR( TO_TIMESTAMP("block_timestamp" / 1000000) ) AS "year",
        "value",
        'input'                                           AS "rec_type"
    FROM CRYPTO.CRYPTO_BITCOIN."INPUTS"
), 
 
/* yearly averages using only OUTPUT-records from the merged set */
yearly_outputs AS (
    SELECT
        "year",
        AVG("value") AS "avg_output_value"
    FROM merged_io
    WHERE "rec_type" = 'output'
    GROUP BY "year"
),

/* yearly averages straight from Transactions table */
yearly_tx AS (
    SELECT
        YEAR( TO_TIMESTAMP("block_timestamp" / 1000000) ) AS "year",
        AVG("output_value")                               AS "avg_tx_output_value"
    FROM CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    GROUP BY "year"
)

/* difference (Outputs-avg  minus  Transactions-avg) – only common years */
SELECT
    o."year",
    o."avg_output_value" - t."avg_tx_output_value" AS "avg_diff"
FROM yearly_outputs o
JOIN yearly_tx     t
  ON o."year" = t."year"
ORDER BY o."year";