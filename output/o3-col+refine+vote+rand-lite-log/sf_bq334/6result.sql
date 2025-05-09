WITH merged_io AS (
    /* combine inputs & outputs, tag the record type */
    SELECT 
        'output' AS "rec_type",
        "block_timestamp",
        "value"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    
    UNION ALL
    
    SELECT 
        'input'  AS "rec_type",
        "block_timestamp",
        "value"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS
),
/* yearly average taken from the merged (but filtered to OUTPUT rows) */
avg_merged AS (
    SELECT 
        EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000)) AS "year",
        AVG("value")                                                  AS "avg_output_value_merged"
    FROM merged_io
    WHERE "rec_type" = 'output'
    GROUP BY "year"
),
/* yearly average taken directly from TRANSACTIONS table */
avg_tx AS (
    SELECT 
        EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000)) AS "year",
        AVG("output_value")                                           AS "avg_tx_output_value"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    GROUP BY "year"
)
/* join the two result-sets and show the difference */
SELECT 
    m."year",
    m."avg_output_value_merged",
    t."avg_tx_output_value",
    m."avg_output_value_merged" - t."avg_tx_output_value" AS "difference"
FROM avg_merged m
JOIN avg_tx    t  ON m."year" = t."year"
ORDER BY m."year";