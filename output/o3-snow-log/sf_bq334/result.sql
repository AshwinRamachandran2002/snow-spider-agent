WITH merged AS (
    /* merge INPUTS and OUTPUTS then keep only OUTPUT rows */
    SELECT "block_timestamp",
           CAST("value" AS DOUBLE) AS "value"
    FROM (
          SELECT "block_timestamp",
                 "value",
                 'output' AS "rec_type"
          FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS
          UNION ALL
          SELECT "block_timestamp",
                 "value",
                 'input'  AS "rec_type"
          FROM CRYPTO.CRYPTO_BITCOIN.INPUTS
    )
    WHERE "rec_type" = 'output'
),
outputs_yearly AS (
    SELECT
        EXTRACT(YEAR FROM TO_TIMESTAMP("block_timestamp" / 1000000)) AS "year",
        AVG("value") AS "avg_outputs"
    FROM merged
    GROUP BY "year"
),
tx_yearly AS (
    SELECT
        EXTRACT(YEAR FROM TO_TIMESTAMP("block_timestamp" / 1000000)) AS "year",
        AVG(CAST("output_value" AS DOUBLE)) AS "avg_tx"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "output_value" IS NOT NULL
    GROUP BY "year"
)
SELECT
    o."year",
    o."avg_outputs" - t."avg_tx" AS "diff_avg_value"
FROM outputs_yearly o
JOIN tx_yearly t
  ON o."year" = t."year"
ORDER BY o."year";