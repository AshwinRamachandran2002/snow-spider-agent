WITH merged_outputs AS (
    SELECT
        EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000)) AS "year",
        AVG("value"::FLOAT)                                          AS "avg_output_value_merged"
    FROM CRYPTO.CRYPTO_BITCOIN."OUTPUTS"
    GROUP BY "year"
),
tx_outputs AS (
    SELECT
        EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000)) AS "year",
        AVG("output_value"::FLOAT)                                   AS "avg_output_value_tx"
    FROM CRYPTO.CRYPTO_BITCOIN."TRANSACTIONS"
    GROUP BY "year"
)
SELECT
    m."year",
    m."avg_output_value_merged" - t."avg_output_value_tx" AS "avg_value_difference"
FROM merged_outputs m
JOIN tx_outputs     t
  ON m."year" = t."year"
ORDER BY m."year";