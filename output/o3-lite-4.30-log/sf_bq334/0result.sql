WITH merged_io AS (
    SELECT "block_timestamp" AS block_ts,
           'output'          AS record_type,
           "value"           AS amount
    FROM   CRYPTO.CRYPTO_BITCOIN.OUTPUTS
    UNION ALL
    SELECT "block_timestamp" AS block_ts,
           'input'           AS record_type,
           "value"           AS amount
    FROM   CRYPTO.CRYPTO_BITCOIN.INPUTS
),
merged_outputs_yearly AS (
    SELECT
        EXTRACT(year FROM TO_TIMESTAMP(block_ts / 1000000.0)) AS year,
        AVG(amount)                                           AS avg_output_value
    FROM   merged_io
    WHERE  record_type = 'output'
      AND  block_ts IS NOT NULL
    GROUP BY year
),
tx_yearly AS (
    SELECT
        EXTRACT(year FROM TO_TIMESTAMP("block_timestamp" / 1000000.0)) AS year,
        AVG("output_value")                                             AS avg_tx_output_value
    FROM   CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE  "block_timestamp" IS NOT NULL
    GROUP BY year
)
SELECT
    o.year,
    ROUND(o.avg_output_value - t.avg_tx_output_value, 4) AS avg_output_value_difference
FROM   merged_outputs_yearly o
JOIN   tx_yearly            t
       ON o.year = t.year
ORDER  BY o.year;