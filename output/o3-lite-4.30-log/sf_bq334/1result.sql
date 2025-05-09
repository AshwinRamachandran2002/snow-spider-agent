WITH "merged_outputs" AS (
    SELECT
        DATE_PART('year', TO_TIMESTAMP("block_timestamp" / 1000000))       AS "year",
        AVG("value")                                                       AS "avg_output_value_btc"
    FROM (
        SELECT 'OUTPUT' AS "rec_type",
               "value",
               "block_timestamp"
        FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
        UNION ALL
        SELECT 'INPUT'  AS "rec_type",
               "value",
               "block_timestamp"
        FROM CRYPTO.CRYPTO_BITCOIN.INPUTS
    ) AS io
    WHERE io."rec_type" = 'OUTPUT'
    GROUP BY "year"
),
"tx_avg" AS (
    SELECT
        DATE_PART('year', TO_TIMESTAMP("block_timestamp" / 1000000))       AS "year",
        AVG("output_value")                                                AS "avg_tx_output_value_btc"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    GROUP BY "year"
)
SELECT
    m."year",
    ROUND(m."avg_output_value_btc" - t."avg_tx_output_value_btc", 4)       AS "avg_output_value_difference"
FROM "merged_outputs" m
JOIN "tx_avg"        t ON m."year" = t."year"
ORDER BY
    m."year";