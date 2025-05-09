/*  Annual difference between
    1) Average value of Bitcoin outputs that were later spent
       (OUTPUTS joined to INPUTS on spent_transaction_hash)
    2) Average output_value recorded in TRANSACTIONS

    Result = (avg_spent_outputs − avg_transactions)
*/
WITH spent_outputs AS (
    SELECT
        SUBSTR(CAST(o."block_timestamp" AS STRING), 1, 4)         AS "year",
        o."value"                                                 AS "output_value"
    FROM CRYPTO.CRYPTO_BITCOIN.OUTPUTS  o
    JOIN CRYPTO.CRYPTO_BITCOIN.INPUTS   i
      ON o."transaction_hash" = i."spent_transaction_hash"
    WHERE o."block_timestamp" IS NOT NULL
),
avg_spent_outputs AS (
    SELECT
        "year",
        AVG("output_value")                                       AS "avg_spent_output_value"
    FROM spent_outputs
    GROUP BY "year"
),
avg_tx_outputs AS (
    SELECT
        SUBSTR(CAST("block_timestamp" AS STRING), 1, 4)           AS "year",
        AVG("output_value")                                       AS "avg_tx_output_value"
    FROM CRYPTO.CRYPTO_BITCOIN.TRANSACTIONS
    WHERE "block_timestamp" IS NOT NULL
    GROUP BY "year"
)
SELECT
    s."year",
    s."avg_spent_output_value",
    t."avg_tx_output_value",
    s."avg_spent_output_value" - t."avg_tx_output_value"          AS "difference"
FROM avg_spent_outputs s
JOIN avg_tx_outputs   t
  ON s."year" = t."year"
ORDER BY s."year";