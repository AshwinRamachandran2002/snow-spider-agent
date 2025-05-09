WITH all_records AS (
    /* merge INPUTS and OUTPUTS, tagging their origin */
    SELECT 
        "block_timestamp",
        "value",
        'output' AS "record_type"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    
    UNION ALL
    
    SELECT 
        "block_timestamp",
        "value",
        'input'  AS "record_type"
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS
),

/* yearly average based on the merged table but keeping only OUTPUT rows */
output_yearly AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6), 'YYYY') AS "year",
        AVG("value")                                               AS "avg_output_value"
    FROM all_records
    WHERE "record_type" = 'output'
    GROUP BY "year"
),

/* yearly average using the TRANSACTIONS table’s output_value column */
tx_yearly AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ("block_timestamp" / 1e6), 'YYYY') AS "year",
        AVG("output_value")                                         AS "avg_tx_output_value"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    GROUP BY "year"
)

/* differences for years available in BOTH methods */
SELECT
    o."year",
    o."avg_output_value" - t."avg_tx_output_value" AS "difference"
FROM output_yearly o
JOIN tx_yearly   t ON o."year" = t."year"
ORDER BY o."year";