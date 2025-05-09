WITH combined AS (
    /* merge INPUTS and OUTPUTS, keep a flag to identify record type */
    SELECT 
        "block_timestamp"                                              AS "ts",
        TO_NUMBER("value")                                             AS "val",
        'output'                                                       AS "record_type"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    
    UNION ALL
    
    SELECT 
        "block_timestamp",
        TO_NUMBER("value"),
        'input'
    FROM CRYPTO.CRYPTO_BITCOIN.INPUTS
),
merged_yearly AS (
    /* keep only outputs and calculate yearly average value */
    SELECT
        EXTRACT(YEAR FROM TO_TIMESTAMP("ts" / 1e6))                    AS "year",
        AVG("val")                                                     AS "merged_avg"
    FROM combined
    WHERE "record_type" = 'output'
    GROUP BY 1
),
tx_yearly AS (
    /* yearly average of output_value directly from TRANSACTIONS table */
    SELECT
        EXTRACT(YEAR FROM TO_TIMESTAMP("block_timestamp" / 1e6))       AS "year",
        AVG(TO_NUMBER("output_value"))                                 AS "tx_avg"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    GROUP BY 1
)
SELECT
    m."year",
    m."merged_avg" - t."tx_avg"                                        AS "difference"
FROM merged_yearly m
JOIN tx_yearly   t
  ON m."year" = t."year"
ORDER BY m."year";