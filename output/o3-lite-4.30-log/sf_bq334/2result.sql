WITH all_io AS (           -- merge inputs & outputs
        SELECT 'OUTPUT' AS "rec_type", "block_number", "value"
        FROM   CRYPTO.CRYPTO_BITCOIN.OUTPUTS
        UNION ALL
        SELECT 'INPUT'  AS "rec_type", "block_number", "value"
        FROM   CRYPTO.CRYPTO_BITCOIN.INPUTS
),
merged_avg AS (            -- yearly average using only the OUTPUT rows
        SELECT  YEAR(b."timestamp_month")              AS "year",
                AVG(a."value")                         AS "avg_output_value_merged"
        FROM    all_io a
        JOIN    CRYPTO.CRYPTO_BITCOIN.BLOCKS b
               ON a."block_number" = b."number"
        WHERE   a."rec_type" = 'OUTPUT'
        GROUP BY YEAR(b."timestamp_month")
),
tx_avg AS (                -- yearly average straight from the transactions table
        SELECT  YEAR(b."timestamp_month")              AS "year",
                AVG(t."output_value")                  AS "avg_output_value_tx"
        FROM    CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS t
        JOIN    CRYPTO.CRYPTO_BITCOIN.BLOCKS b
               ON t."block_number" = b."number"
        GROUP BY YEAR(b."timestamp_month")
)
SELECT  m."year",
        ROUND(m."avg_output_value_merged" - t."avg_output_value_tx", 4)
        AS "avg_output_value_difference"
FROM    merged_avg m
JOIN    tx_avg     t  ON m."year" = t."year"
ORDER BY m."year";